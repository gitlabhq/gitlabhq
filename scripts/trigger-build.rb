#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require 'yaml'
require 'json'
require 'open3'
require 'tempfile'
require 'httparty'
require 'logger'

# Monkeypatch gitlab gem in order to increase per_page size when fetching registry repositories
# rubocop:disable Style/ClassAndModuleChildren, Gitlab/NoCodeCoverageComment -- monkeypatch
# :nocov:
#
# TODO: Remove this monkeypatch once https://github.com/NARKOZ/gitlab/pull/710 is part of a new gem release (currently v5.1.0 doens't contain it) and the release is used in this project.
class Gitlab::Client
  module ContainerRegistry
    def registry_repositories(project, options = {})
      get("/projects/#{url_encode project}/registry/repositories", query: options)
    end
  end
end
# :nocov:
# rubocop:enable Style/ClassAndModuleChildren, Gitlab/NoCodeCoverageComment

module Trigger
  def self.ee?
    # Support former project name for `dev`
    %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME'])
  end

  def self.non_empty_variable_value(variable)
    variable_value = ENV[variable]

    return if variable_value.nil? || variable_value.empty?

    variable_value
  end

  def self.variables_for_env_file(variables)
    variables.map do |key, value|
      %(#{key}=#{value})
    end.join("\n")
  end

  class Base
    # Can be overridden
    STABLE_BRANCH_REGEX = /^[\d-]+-stable(-ee|-jh)?$/
    def access_token
      ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
    end

    def invoke!
      pipeline_variables = variables

      puts "Triggering downstream pipeline on #{downstream_project_path}"
      puts "with variables #{pipeline_variables}"

      pipeline = downstream_client.run_trigger(
        downstream_project_path,
        trigger_token,
        ref,
        pipeline_variables)

      puts "Triggered downstream pipeline: #{pipeline.web_url}\n"
      puts "Waiting for downstream pipeline status"

      Trigger::Pipeline.new(downstream_project_path, pipeline.id, downstream_client)
    end

    def variables
      simple_forwarded_variables.merge(base_variables, extra_variables, version_file_variables)
    end

    def simple_forwarded_variables
      {
        'TRIGGER_SOURCE' => ENV['CI_JOB_URL'],
        'TOP_UPSTREAM_SOURCE_PROJECT' => ENV['CI_PROJECT_PATH'],
        'TOP_UPSTREAM_SOURCE_REF' => ENV['CI_COMMIT_REF_NAME'],
        'TOP_UPSTREAM_SOURCE_JOB' => ENV['CI_JOB_URL'],
        'TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID' => ENV['CI_MERGE_REQUEST_PROJECT_ID'],
        'TOP_UPSTREAM_MERGE_REQUEST_IID' => ENV['CI_MERGE_REQUEST_IID']
      }
    end

    private

    def com_gitlab_client
      @com_gitlab_client ||= Gitlab.client(
        endpoint: endpoint,
        private_token: access_token
      )
    end

    # This client is used for downstream build and pipeline status
    # Can be overridden
    def downstream_client
      com_gitlab_client
    end

    # Must be overridden
    def downstream_project_path
      raise NotImplementedError
    end

    # Must be overridden
    def ref_param_name
      raise NotImplementedError
    end

    # Can be overridden
    def primary_ref
      'main'
    end

    # Can be overridden
    def trigger_token
      ENV['CI_JOB_TOKEN']
    end

    # Can be overridden
    def extra_variables
      {}
    end

    # Can be overridden
    def version_param_value(version_file)
      ENV[version_file]&.strip || File.read(version_file).strip
    end

    # Can be overridden
    def trigger_stable_branch_if_detected?
      false
    end

    def stable_branch?
      ENV['CI_COMMIT_REF_NAME'] =~ STABLE_BRANCH_REGEX
    end

    def mr_target_stable_branch?
      ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] =~ STABLE_BRANCH_REGEX
    end

    def fallback_ref
      return primary_ref unless trigger_stable_branch_if_detected?

      if stable_branch?
        normalize_stable_branch_name(ENV['CI_COMMIT_REF_NAME'])
      elsif mr_target_stable_branch?
        normalize_stable_branch_name(ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'])
      else
        primary_ref
      end
    end

    def normalize_stable_branch_name(branch_name)
      if ENV['CI_PROJECT_NAMESPACE'] == 'gitlab-cn'
        branch_name.delete_suffix('-jh')
      elsif ["gitlab-org", "gitlab-org/security"].include?(ENV['CI_PROJECT_NAMESPACE'])
        branch_name.delete_suffix('-ee')
      end
    end

    def ref
      ENV.fetch(ref_param_name, fallback_ref)
    end

    def base_variables
      {
        'GITLAB_REF_SLUG' => ENV['CI_COMMIT_TAG'] ? ENV['CI_COMMIT_REF_NAME'] : ENV['CI_COMMIT_REF_SLUG'],
        'TRIGGERED_USER' => ENV['TRIGGERED_USER'] || ENV['GITLAB_USER_NAME'],
        'TOP_UPSTREAM_SOURCE_SHA' => ENV['CI_COMMIT_SHA']
      }
    end

    # Read version files from all components
    def version_file_variables
      Dir.glob("*_VERSION").each_with_object({}) do |version_file, params| # rubocop:disable Rails/IndexWith -- Non-rails CI script
        params[version_file] = version_param_value(version_file)
      end
    end

    def endpoint
      return "https://jihulab.com/api/v4" if ENV['CI_PROJECT_NAMESPACE'] == 'gitlab-cn'

      "https://gitlab.com/api/v4"
    end
  end

  # Variable creation for downstream CNG build triggers
  #
  # This class additionally contains logic to check if component versions are already present in the container registry
  # If they are, it adds those jobs to the SKIP_JOB_REGEX variable to skip them in the CNG build pipeline
  #
  # In order to correctly compute container versions and skip jobs, following actions are performed:
  #   * container version shell script is fetched from upstream
  #   * versions.yml file is fetched which contains most of variables required for container version calculation
  #   * image digest of stable Debian and Alpine images are fetched (alpine-stable and alpine-debian jobs functionality)
  #   * all container versions are computed using same logic as CNG build pipeline
  #   * registry is checked for image existence and appropriate jobs are added to skip regex pattern
  #
  class CNG < Base
    TriggerRefBranchCreationFailed = Class.new(StandardError)

    ASSETS_HASH = "cached-assets-hash.txt"
    DEFAULT_DEBIAN_IMAGE = "debian:bookworm-slim"
    DEFAULT_ALPINE_IMAGE = "alpine:3.20"
    DEFAULT_SKIPPED_JOBS = %w[final-images-listing].freeze
    DEFAULT_SKIPPED_JOB_REGEX = "/#{DEFAULT_SKIPPED_JOBS.join('|')}/".freeze
    STABLE_BASE_JOBS = %w[alpine-stable debian-stable].freeze

    def variables
      hash = without_trigger_vars(super.dup)

      unless skip_redundant_jobs?
        logger.info("Skipping redundant jobs is disabled, skipping existing container image check")
        return hash
      end

      hash.merge({
        **deploy_component_tag_variables,
        'SKIP_IMAGE_TAGGING' => "true",
        'SKIP_JOB_REGEX' => skip_job_regex,
        'DEBIAN_IMAGE' => debian_image,
        'DEBIAN_DIGEST' => debian_image.split('@').last,
        'DEBIAN_BUILD_ARGS' => "--build-arg DEBIAN_IMAGE=#{ENV['GITLAB_DEPENDENCY_PROXY']}#{debian_image}",
        'ALPINE_IMAGE' => alpine_image,
        'ALPINE_DIGEST' => alpine_image.split('@').last,
        'ALPINE_BUILD_ARGS' => "--build-arg ALPINE_IMAGE=#{ENV['GITLAB_DEPENDENCY_PROXY']}#{alpine_image}"
      })
    rescue TriggerRefBranchCreationFailed => e
      # raise if pipeline runs in MR that updates ref to make sure branch for trigger is created
      raise(e) if ref_update_mr?

      logger.error("Error while creating trigger ref branch, err: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      logger.error("Falling back to default variables")
      without_trigger_vars(super.dup)
    rescue StandardError => e
      # if skipping redundant jobs is enabled and fetching jobs to skip failed, attempt fallback to default variables
      raise(e) unless skip_redundant_jobs?

      logger.error("Error while calculating variables, err: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      logger.error("Falling back to default variables")
      hash
    end

    def simple_forwarded_variables
      super.merge({
        'TOP_UPSTREAM_SOURCE_REF_SLUG' => ENV['CI_COMMIT_REF_SLUG']
      })
    end

    private

    # overridden base class methods
    def downstream_project_path
      ENV.fetch('CNG_PROJECT_PATH', 'gitlab-org/build/CNG-mirror')
    end

    def ref
      return @ref if @ref
      return @ref = super if cng_commit_sha.to_s.empty?

      # TODO: remove this hack once https://gitlab.com/gitlab-org/gitlab/-/issues/369583 is resolved
      trigger_branch_name = "trigger-refs/#{cng_commit_sha}"
      return @ref = trigger_branch_name if branch_exists?(trigger_branch_name)

      downstream_client.create_branch(downstream_project_path, trigger_branch_name, cng_commit_sha)
      logger.info("Created temp trigger branch '#{trigger_branch_name}' for commit '#{cng_commit_sha}'")
      @ref = trigger_branch_name
    rescue StandardError => e
      # redundancy in case explicit branch existence api request failed
      return trigger_branch_name if e.message.include?("already exists")

      @ref = super
      raise TriggerRefBranchCreationFailed, e.message
    end

    def ref_param_name
      'CNG_BRANCH'
    end

    def primary_ref
      return "main-jh" if ENV['CI_PROJECT_NAMESPACE'] == 'gitlab-cn'

      "master"
    end

    def trigger_stable_branch_if_detected?
      true
    end

    def gitlab_ref_slug
      if ENV['CI_COMMIT_TAG']
        ENV['CI_COMMIT_REF_NAME']
      else
        ENV['CI_COMMIT_SHA']
      end
    end

    def gitlab_version
      ENV['CI_COMMIT_SHA']
    end

    def base_variables
      super.merge('GITLAB_REF_SLUG' => gitlab_ref_slug)
    end

    def extra_variables
      {
        "TRIGGER_BRANCH" => ref,
        "GITLAB_VERSION" => gitlab_version,
        "GITLAB_TAG" => ENV['CI_COMMIT_TAG'], # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
        "FORCE_RAILS_IMAGE_BUILDS" => 'true',
        "CE_PIPELINE" => Trigger.ee? ? nil : "true", # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
        "EE_PIPELINE" => Trigger.ee? ? "true" : nil, # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
        "FULL_RUBY_VERSION" => RUBY_VERSION,
        "SKIP_JOB_REGEX" => DEFAULT_SKIPPED_JOB_REGEX,
        "DEBIAN_IMAGE" => DEFAULT_DEBIAN_IMAGE, # Make sure default values are always set to not end up as empty string
        "ALPINE_IMAGE" => DEFAULT_ALPINE_IMAGE, # Make sure default values are always set to not end up as empty string
        **default_build_vars
      }
    end

    def version_param_value(_version_file)
      raw_version = super

      # if the version matches semver format, treat it as a tag and prepend `v`
      if Regexp.compile(/^\d+\.\d+\.\d+(-rc\d+)?(-ee)?$/).match?(raw_version)
        "v#{raw_version}"
      else
        raw_version
      end
    end

    def access_token
      ENV["CNG_ACCESS_TOKEN"].then { |token| token.to_s.empty? ? super : token }
    end
    # overridden base class methods

    # Logger with file output
    #
    # @return [Logger]
    def logger
      @logger ||= Logger.new(ENV.fetch("CNG_VAR_SETUP_LOG_FILE", "tmp/cng-var-setup.log"))
    end

    # Specific commit sha to be used instead of branch if defined
    #
    # @return [String]
    def cng_commit_sha
      @cng_commit_sha ||= ENV['CNG_COMMIT_SHA']
    end

    # Default variables used in CNG builds that affect container version values
    #
    # @return [Hash]
    def default_build_vars
      @default_build_vars ||= {
        "CONTAINER_VERSION_SUFFIX" => ENV.fetch("CI_PROJECT_PATH_SLUG", "upstream-trigger"),
        "CACHE_BUSTER" => "false",
        "ARCH_LIST" => ENV.fetch("ARCH_LIST", "amd64")
      }
    end

    # Skip redundant build jobs by calculating if container images are already present in the registry
    #
    # @return [Boolean]
    def skip_redundant_jobs?
      ENV["CNG_SKIP_REDUNDANT_JOBS"] == "true"
    end

    # Pipeline is part of MR that updates cng-mirror ref
    #
    # @return [Boolean]
    def ref_update_mr?
      ENV["CI_MERGE_REQUEST_TARGET_BRANCH_NAME"]&.match?(%r{renovate-e2e/cng\S+digest})
    end

    # Skipped job regex based on existing container tags in the registry
    #
    # @return [String]
    def skip_job_regex
      "/#{[*DEFAULT_SKIPPED_JOBS, *STABLE_BASE_JOBS, *skippable_jobs].join('|')}/"
    end

    # Branch existence check
    #
    # @param branch_name [String]
    # @return [Boolean]
    def branch_exists?(branch_name)
      !!downstream_client.branch(downstream_project_path, branch_name)
    rescue Gitlab::Error::ResponseError
      false
    end

    def without_trigger_vars(hash)
      hash.except('TRIGGER_SOURCE', 'TRIGGERED_USER')
    end

    # Repository file tree in form of the output of `git ls-tree` command
    #
    # @return [String]
    def repo_tree
      logger.info("Fetching repo tree for ref '#{ref}'")
      downstream_client
        .repo_tree(downstream_project_path, ref: ref, per_page: 100).auto_paginate
        .select { |node| node["type"] == "tree" }
        .map { |node| "#{node['mode']} #{node['type']} #{node['id']}  #{node['path']}" }
        .join("\n")
    end

    # Script used for container version calculations in CNG build jobs
    #
    # @return [String]
    def container_versions_script
      logger.info("Fetching container versions script for ref '#{ref}'")
      downstream_client.file_contents(
        downstream_project_path,
        "build-scripts/container_versions.sh",
        ref
      )
    end

    # Debian image with digest
    #
    # @return [String]
    def debian_image
      @debian_image ||= docker_image_with_digest(cng_versions["DEBIAN_IMAGE"])
    end

    # Alpine image with digest
    #
    # @return [String]
    def alpine_image
      @alpine_image ||= docker_image_with_digest(cng_versions["ALPINE_IMAGE"])
    end

    # Edition postfix
    #
    # @return [String]
    def edition
      @edition ||= Trigger.ee? ? "ee" : "ce"
    end

    # Component versions used in CNG builds
    #
    # @return [Hash]
    def cng_versions
      @cng_versions ||= YAML
        .safe_load(downstream_client.file_contents(downstream_project_path, "ci_files/variables.yml", ref))
        .fetch("variables")
    end

    # Environment variables required for container version fetching
    # All these variables influence final container version values
    #
    # @return [Hash]
    def version_fetch_env_variables
      {
        **cng_versions,
        **version_file_variables,
        **default_build_vars,
        "GITLAB_VERSION" => gitlab_version,
        "RUBY_VERSION" => RUBY_VERSION,
        "DEBIAN_DIGEST" => debian_image.split("@").last,
        "ALPINE_DIGEST" => alpine_image.split("@").last,
        "REPOSITORY_TREE" => repo_tree
      }
    end

    # Image tags used by CNG deployments
    #
    # @return [Hash]
    def deploy_component_tag_variables
      {
        "GITALY_TAG" => container_versions["gitaly"],
        "GITLAB_SHELL_TAG" => container_versions["gitlab-shell"],
        "GITLAB_TOOLBOX_TAG" => container_versions["gitlab-toolbox-#{edition}"],
        "GITLAB_SIDEKIQ_TAG" => container_versions["gitlab-sidekiq-#{edition}"],
        "GITLAB_WEBSERVICE_TAG" => container_versions["gitlab-webservice-#{edition}"],
        "GITLAB_WORKHORSE_TAG" => container_versions["gitlab-workhorse-#{edition}"],
        "GITLAB_KAS_TAG" => container_versions["gitlab-kas"]
      }
    end

    # Container versions for all components in CNG build pipeline
    #
    # @return [Hash]
    def container_versions
      @container_versions ||= Tempfile.create('container-versions') do |file|
        file.write(container_versions_script)
        file.close

        build_vars = version_fetch_env_variables
        logger.info("Computing container versions using following env variables:\n#{JSON.pretty_generate(build_vars)}")
        out, status = Open3.capture2e(build_vars, "bash -c 'source #{file.path} && get_all_versions'")
        raise "Failed to fetch container versions! #{out}" unless status.success?

        component_versions = out.split("\n")
        unless component_versions.all? { |line| line.match?(/^[A-Za-z0-9_\-]+=[^=]+$/) }
          raise "Invalid container versions output format! Expected key=value pairs got:\n#{out}"
        end

        component_versions
          .to_h { |entry| entry.split("=") }
          .reject { |name, _version| Trigger.ee? ? name.end_with?("-ce") : name.end_with?("-ee") }
          .tap { |versions| logger.info("Computed container versions:\n#{JSON.pretty_generate(versions)}") }
      end
    end

    # List of jobs that can be skipped because tag is already present in the registry
    #
    # @return [Array]
    def skippable_jobs
      jobs = container_versions.keys
      logger.info("Fetching container registry repositories for project '#{downstream_project_path}'")
      repositories = downstream_client.registry_repositories(downstream_project_path, per_page: 100).auto_paginate
      build_repositories = repositories.each_with_object({}) do |repo, hash|
        job = jobs.find { |job| repo.name.end_with?(job) }
        next unless job

        hash[job] = repo.id
      end
      logger.info("Checking repositories (#{build_repositories.keys.join(', ')}) for existing tags")
      existing_tags = container_versions.select do |job, tag|
        downstream_client.registry_repository_tag(downstream_project_path, build_repositories[job], tag)
        logger.info("Tag '#{tag}' exists in the registry, job '#{job}' will be skipped")
      rescue Gitlab::Error::ResponseError => e
        if e.is_a?(Gitlab::Error::NotFound)
          logger.info("Tag '#{tag}' does not exist in the registry, job '#{job}' will not skipped")
        else
          logger.error("Failed to do a tag '#{tag}' lookup, err: #{e.message}, job '#{job}' will not be skipped")
        end

        false
      end

      existing_tags.keys
    end

    # rubocop:disable Gitlab/HTTParty -- CI script

    # Fetch Docker image with digest from DockerHub
    #
    # @param docker_image [String]
    # @return [String]
    def docker_image_with_digest(docker_image)
      image, tag = docker_image.split(":")

      logger.info("Fetching digest for image '#{docker_image}'")
      auth_url = "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/#{image}:pull"
      auth_response = HTTParty.get(auth_url)
      raise "Failed to get auth token" unless auth_response.success?

      token = JSON.parse(auth_response.body)['token']
      manifest_url = "https://registry.hub.docker.com/v2/library/#{image}/manifests/#{tag}"
      response = HTTParty.head(manifest_url, headers: {
        'Authorization' => "Bearer #{token}",
        'Accept' => 'application/vnd.docker.distribution.manifest.v2+json'
      })
      raise "Failed to fetch image '#{docker_image}' digest" unless response.success?

      digest = response.headers['docker-content-digest'] || raise("Failed to get image digest")
      "#{image}:#{tag}@#{digest}"
    end
    # rubocop:enable Gitlab/HTTParty -- CI script
  end

  # For GitLab documentation review apps
  class Docs < Base
    def access_token
      ENV['DOCS_PROJECT_API_TOKEN'] || super
    end

    SUCCESS_MESSAGE = <<~MSG
    => You should now be able to preview your changes under the following URL:

    %<app_url>s

    => For more information, see the documentation
    => https://docs.gitlab.com/ee/development/documentation/review_apps.html

    => If something doesn't work, drop a line in the #docs chat channel.
    MSG

    def deploy!
      invoke!.wait!
      display_success_message
    end

    #
    # Remove a remote environment in the docs-gitlab-com project.
    #
    def cleanup!
      environment = com_gitlab_client.environments(downstream_project_path, name: downstream_environment).first
      return unless environment

      environment = com_gitlab_client.stop_environment(downstream_project_path, environment.id)
      if environment.state == 'stopped'
        puts "=> Downstream environment '#{downstream_environment}' stopped."
      else
        puts "=> Downstream environment '#{downstream_environment}' failed to stop."
      end
    end

    private

    def downstream_environment
      "upstream-review/mr-${CI_MERGE_REQUEST_IID}"
    end

    def review_slug
      identifier = ENV['CI_MERGE_REQUEST_IID'] || ENV['CI_COMMIT_REF_SLUG']

      "#{project_slug}-#{identifier}"
    end

    def downstream_project_path
      ENV.fetch('DOCS_PROJECT_PATH', 'gitlab-org/technical-writing/docs-gitlab-com')
    end

    def ref_param_name
      'DOCS_BRANCH'
    end

    def trigger_token
      ENV['DOCS_TRIGGER_TOKEN']
    end

    def extra_variables
      {
        "BRANCH_#{project_slug.upcase}" => ENV['CI_COMMIT_REF_NAME'],
        "MERGE_REQUEST_IID_#{project_slug.upcase}" => ENV['CI_MERGE_REQUEST_IID'],
        "REVIEW_SLUG" => review_slug
      }
    end

    def project_slug
      case ENV['CI_PROJECT_PATH']
      when 'gitlab-org/gitlab-foss'
        'ce'
      when 'gitlab-org/gitlab'
        'ee'
      when 'gitlab-org/gitlab-runner'
        'runner'
      when 'gitlab-org/omnibus-gitlab'
        'omnibus'
      when 'gitlab-org/charts/gitlab'
        'charts'
      when 'gitlab-org/cloud-native/gitlab-operator'
        'operator'
      end
    end

    def app_url
      "https://docs.gitlab.com/upstream-review-mr-#{review_slug}/"
    end

    def display_success_message
      puts format(SUCCESS_MESSAGE, app_url: app_url)
    end
  end

  class DatabaseTesting < Base
    IDENTIFIABLE_NOTE_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note'

    def invoke!
      pipeline = super
      project_path = variables['TOP_UPSTREAM_SOURCE_PROJECT']
      merge_request_id = variables['TOP_UPSTREAM_MERGE_REQUEST_IID']
      comment = <<~COMMENT.strip
        <!-- #{IDENTIFIABLE_NOTE_TAG} -->
        Started database testing [pipeline](https://ops.gitlab.net/#{downstream_project_path}/-/pipelines/#{pipeline.id}) (limited access). This comment will be updated once the pipeline has finished running.
      COMMENT

      # Look for an existing note
      db_testing_notes = com_gitlab_client
        .merge_request_notes(project_path, merge_request_id)
        .auto_paginate.select do |note|
          note.body.include?(IDENTIFIABLE_NOTE_TAG)
        end

      return unless db_testing_notes.empty?

      # This is the first note
      note = com_gitlab_client.create_merge_request_note(project_path, merge_request_id, comment)

      puts "Posted comment to:\n"
      puts "https://gitlab.com/#{project_path}/-/merge_requests/#{merge_request_id}#note_#{note.id}"
    end

    private

    def ops_gitlab_client
      # No access token is needed here - we only use this client to trigger pipelines,
      # and the trigger token authenticates the request to the pipeline
      @ops_gitlab_client ||= Gitlab.client(
        endpoint: 'https://ops.gitlab.net/api/v4'
      )
    end

    def downstream_client
      ops_gitlab_client
    end

    def trigger_token
      ENV['GITLABCOM_DATABASE_TESTING_TRIGGER_TOKEN']
    end

    def downstream_project_path
      ENV.fetch('GITLABCOM_DATABASE_TESTING_PROJECT_PATH', 'gitlab-com/database-team/gitlab-com-database-testing')
    end

    def extra_variables
      {
        'GITLAB_COMMIT_SHA' => Trigger.non_empty_variable_value('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA') || ENV['CI_COMMIT_SHA'],
        'TRIGGERED_USER_LOGIN' => ENV['GITLAB_USER_LOGIN'],
        'TOP_UPSTREAM_SOURCE_SHA' => Trigger.non_empty_variable_value('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA') || ENV['CI_COMMIT_SHA']
      }
    end

    def ref_param_name
      'GITLABCOM_DATABASE_TESTING_TRIGGER_REF'
    end

    def primary_ref
      'master'
    end
  end

  class Pipeline
    INTERVAL = 60 # seconds
    MAX_DURATION = 3600 * 3 # 3 hours

    attr_reader :id

    def self.unscoped_class_name
      name.split('::').last
    end

    def self.gitlab_api_method_name
      unscoped_class_name.downcase
    end

    def initialize(project, id, gitlab_client)
      @project = project
      @id = id
      @gitlab_client = gitlab_client
      @start_time = Time.now.to_i
    end

    def wait!
      (MAX_DURATION / INTERVAL).times do
        case status
        when :created, :pending, :running
          print "."
          sleep INTERVAL
        when :success
          puts "#{self.class.unscoped_class_name} succeeded in #{duration} minutes!"
          return
        else
          raise "#{self.class.unscoped_class_name} did not succeed!"
        end

        $stdout.flush
      end

      raise "#{self.class.unscoped_class_name} timed out after waiting for #{duration} minutes!"
    end

    def duration
      (Time.now.to_i - start_time) / 60
    end

    def status
      gitlab_client.public_send(self.class.gitlab_api_method_name, project, id).status.to_sym # rubocop:disable GitlabSecurity/PublicSend
    rescue Gitlab::Error::Error => error
      puts "Ignoring the following error: #{error}"
      # Ignore GitLab API hiccups. If GitLab is really down, we'll hit the job
      # timeout anyway.
      :running
    end

    private

    attr_reader :project, :gitlab_client, :start_time
  end
end

if $PROGRAM_NAME == __FILE__
  case ARGV[0]
  when 'gitlab-com-database-testing'
    Trigger::DatabaseTesting.new.invoke!
  when 'docs'
    docs_trigger = Trigger::Docs.new

    case ARGV[1]
    when 'deploy'
      docs_trigger.deploy!
    when 'cleanup'
      docs_trigger.cleanup!
    else
      puts 'usage: trigger-build docs <deploy|cleanup>'
      exit 1
    end
  else
    puts "Please provide a valid option:
    docs - Triggers a pipeline that builds a documentation review app by using the docs-gitlab-com project
    omnibus - Triggers a pipeline that builds the omnibus-gitlab package
    gitlab-com-database-testing - Triggers a pipeline that tests database changes on GitLab.com data"
  end
end
