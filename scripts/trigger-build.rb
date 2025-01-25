#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'

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
      Dir.glob("*_VERSION").each_with_object({}) do |version_file, params| # rubocop:disable Rails/IndexWith
        params[version_file] = version_param_value(version_file)
      end
    end

    def endpoint
      return "https://jihulab.com/api/v4" if ENV['CI_PROJECT_NAMESPACE'] == 'gitlab-cn'

      "https://gitlab.com/api/v4"
    end
  end

  class CNG < Base
    ASSETS_HASH = "cached-assets-hash.txt"

    def variables
      # Delete variables that aren't useful when using native triggers.
      super.tap do |hash|
        hash.delete('TRIGGER_SOURCE')
        hash.delete('TRIGGERED_USER')
      end
    end

    private

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

    def base_variables
      super.merge(
        'GITLAB_REF_SLUG' => gitlab_ref_slug
      )
    end

    def extra_variables
      {
        "TRIGGER_BRANCH" => ref,
        "GITLAB_VERSION" => ENV['CI_COMMIT_SHA'],
        "GITLAB_TAG" => ENV['CI_COMMIT_TAG'], # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
        "FORCE_RAILS_IMAGE_BUILDS" => 'true',
        "CE_PIPELINE" => Trigger.ee? ? nil : "true", # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
        "EE_PIPELINE" => Trigger.ee? ? "true" : nil # Always set a value, even an empty string, so that the downstream pipeline can correctly check it.
      }
    end

    def simple_forwarded_variables
      super.merge({
        'TOP_UPSTREAM_SOURCE_REF_SLUG' => ENV['CI_COMMIT_REF_SLUG']
      })
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
  end

  # This is used in:
  # - https://gitlab.com/gitlab-org/gitlab-runner/-/blob/ddaf90761c917a42ed4aab60541b6bc33871fe68/.gitlab/ci/docs.gitlab-ci.yml#L1-47
  # - https://gitlab.com/gitlab-org/charts/gitlab/-/blob/fa348e709e901196803051669b4874b657b4ea91/.gitlab-ci.yml#L497-543
  # - https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/b44483f05c5e22628ba3b49ec4c7f8761c688af0/gitlab-ci-config/gitlab-com.yml#L199-224
  # - https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/b44483f05c5e22628ba3b49ec4c7f8761c688af0/gitlab-ci-config/gitlab-com.yml#L356-380
  class Docs < Base
    def access_token
      ENV['DOCS_PROJECT_API_TOKEN'] || super
    end

    SUCCESS_MESSAGE = <<~MSG
    => You should now be able to preview your changes under the following URL:

    %<app_url>s

    => For more information, see the documentation
    => https://docs.gitlab.com/ee/development/documentation/index.html#previewing-the-changes-live

    => If something doesn't work, drop a line in the #docs chat channel.
    MSG

    def deploy!
      invoke!.wait!
      display_success_message
    end

    #
    # Remove a remote branch in gitlab-docs.
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
      "review/#{ref}#{review_slug}"
    end

    # We prepend the `-` here because we cannot use variable substitution in `environment.name`/`environment.url`
    # Some projects (e.g. `omnibus-gitlab`) use this script for branch pipelines, so we fallback to using `CI_COMMIT_REF_SLUG` for those cases.
    def review_slug
      identifier = ENV['CI_MERGE_REQUEST_IID'] || ENV['CI_COMMIT_REF_SLUG']

      "-#{project_slug}-#{identifier}"
    end

    def downstream_project_path
      ENV.fetch('DOCS_PROJECT_PATH', 'gitlab-org/gitlab-docs')
    end

    def ref_param_name
      'DOCS_BRANCH'
    end

    # `gitlab-org/gitlab-docs` pipeline trigger "Triggered from gitlab-org/gitlab 'review-docs-deploy' job"
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

    # app_url is the URL of the `gitlab-docs` Review App URL defined in
    # https://gitlab.com/gitlab-org/gitlab-docs/-/blob/b38038132cf82a24271bbb294dead7c2f529e275/.gitlab-ci.yml#L383
    def app_url
      "http://#{ref}#{review_slug}.#{ENV['DOCS_REVIEW_APPS_DOMAIN']}/#{project_slug}"
    end

    def display_success_message
      puts format(SUCCESS_MESSAGE, app_url: app_url)
    end
  end

  class DocsHugo < Docs
    def access_token
      ENV['DOCS_HUGO_PROJECT_API_TOKEN'] || super
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

    def trigger_token
      ENV['DOCS_HUGO_TRIGGER_TOKEN']
    end

    def app_url
      "https://new.docs.gitlab.com/upstream-review-mr-#{review_slug}/"
    end
  end

  class DatabaseTesting < Base
    IDENTIFIABLE_NOTE_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note'

    def invoke!
      pipeline = super
      project_path = variables['TOP_UPSTREAM_SOURCE_PROJECT']
      merge_request_id = variables['TOP_UPSTREAM_MERGE_REQUEST_IID']
      comment = "<!-- #{IDENTIFIABLE_NOTE_TAG} --> \nStarted database testing [pipeline](https://ops.gitlab.net/#{downstream_project_path}/-/pipelines/#{pipeline.id}) " \
                "(limited access). This comment will be updated once the pipeline has finished running."

      # Look for an existing note
      db_testing_notes = com_gitlab_client.merge_request_notes(project_path, merge_request_id).auto_paginate.select do |note|
        note.body.include?(IDENTIFIABLE_NOTE_TAG)
      end

      if db_testing_notes.empty?
        # This is the first note
        note = com_gitlab_client.create_merge_request_note(project_path, merge_request_id, comment)

        puts "Posted comment to:\n"
        puts "https://gitlab.com/#{project_path}/-/merge_requests/#{merge_request_id}#note_#{note.id}"
      end
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
  when 'docs-hugo', 'docs'
    docs_trigger = (ARGV[0] == 'docs-hugo' ? Trigger::DocsHugo : Trigger::Docs).new

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
    docs - Triggers a pipline that builds a documentation review app by using the gitlab-docs project
    docs-hugo - Triggers a pipline that builds a documentation review app by using the gitlab-docs-hugo project
    omnibus - Triggers a pipelines that builds the omnibus-gitlab package
    gitlab-com-database-testing - Triggers a pipeline that tests database changes on GitLab.com data"
  end
end
