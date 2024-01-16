#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'gitlab'
require_relative File.expand_path('../../tooling/lib/tooling/helm3_client.rb', __dir__)
require_relative File.expand_path('../../tooling/lib/tooling/kubernetes_client.rb', __dir__)

module ReviewApps
  class AutomatedCleanup
    DEPLOYMENTS_PER_PAGE = 100
    ENVIRONMENT_PREFIX = {
      review_app: 'review/',
      docs_review_app: 'review-docs/'
    }.freeze
    IGNORED_HELM_ERRORS = [
      'transport is closing',
      'error upgrading connection',
      'not found'
    ].freeze
    IGNORED_KUBERNETES_ERRORS = [
      'NotFound'
    ].freeze
    ENVIRONMENTS_NOT_FOUND_THRESHOLD = 3

    def self.parse_args(argv)
      options = {
        dry_run: false
      }

      OptionParser.new do |opts|
        opts.on("-d BOOLEAN", "--dry-run BOOLEAN", String, "Whether to perform a dry-run or not.") do |value|
          options[:dry_run] = true if value == 'true'
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end
      end.parse!(argv)

      options
    end

    # $GITLAB_PROJECT_REVIEW_APP_CLEANUP_API_TOKEN => `Automated Review App Cleanup` project token
    def initialize(
      project_path: ENV['CI_PROJECT_PATH'],
      gitlab_token: ENV['GITLAB_PROJECT_REVIEW_APP_CLEANUP_API_TOKEN'],
      api_endpoint: ENV['CI_API_V4_URL'],
      options: {}
    )
      @project_path                     = project_path
      @gitlab_token                     = gitlab_token
      @api_endpoint                     = api_endpoint
      @dry_run                          = options[:dry_run]
      @environments_not_found_count     = 0
    end

    def gitlab
      @gitlab ||= begin
        Gitlab.configure do |config|
          config.endpoint = api_endpoint
          # gitlab-bot's token "GitLab review apps cleanup"
          config.private_token = gitlab_token
        end

        Gitlab
      end
    end

    def helm
      @helm ||= Tooling::Helm3Client.new
    end

    def kubernetes
      @kubernetes ||= Tooling::KubernetesClient.new
    end

    def perform_gitlab_environment_cleanup!(days_for_delete:)
      puts "Dry-run mode." if dry_run
      puts "Checking for Review Apps not updated in the last #{days_for_delete} days..."

      checked_environments = []
      delete_threshold = threshold_time(days: days_for_delete)
      deployments_look_back_threshold = threshold_time(days: days_for_delete * 5)

      releases_to_delete = []

      # Delete environments via deployments
      gitlab.deployments(project_path, per_page: DEPLOYMENTS_PER_PAGE, sort: 'desc').auto_paginate do |deployment|
        last_deploy = deployment.created_at
        deployed_at = Time.parse(last_deploy)

        break if deployed_at < deployments_look_back_threshold

        environment = deployment.environment

        next unless environment
        next unless environment.name.start_with?(ENVIRONMENT_PREFIX[:review_app])
        next if checked_environments.include?(environment.slug)

        if deployed_at < delete_threshold
          deleted_environment = delete_environment(environment, deployment)

          if deleted_environment
            release = Tooling::Helm3Client::Release.new(name: environment.slug, namespace: environment.slug, revision: 1)
            releases_to_delete << release
          end
        end

        checked_environments << environment.slug
      end

      delete_stopped_environments(environment_type: :review_app, checked_environments: checked_environments, last_updated_threshold: delete_threshold) do |environment|
        releases_to_delete << Tooling::Helm3Client::Release.new(name: environment.slug, namespace: environment.slug, revision: 1, updated: environment.updated_at)
      end

      delete_helm_releases(releases_to_delete)
    end

    def perform_gitlab_docs_environment_cleanup!(days_for_stop:, days_for_delete:)
      puts "Dry-run mode." if dry_run
      puts "Checking for Docs Review Apps not updated in the last #{days_for_stop} days..."

      checked_environments = []
      stop_threshold = threshold_time(days: days_for_stop)
      delete_threshold = threshold_time(days: days_for_delete)
      deployments_look_back_threshold = threshold_time(days: days_for_delete * 5)

      # Delete environments via deployments
      gitlab.deployments(project_path, per_page: DEPLOYMENTS_PER_PAGE, sort: 'desc').auto_paginate do |deployment|
        last_deploy = deployment.created_at
        deployed_at = Time.parse(last_deploy)

        break if deployed_at < deployments_look_back_threshold

        environment = deployment.environment

        next unless environment
        next unless environment.name.start_with?(ENVIRONMENT_PREFIX[:docs_review_app])
        next if checked_environments.include?(environment.slug)

        if deployed_at < stop_threshold
          environment_state = fetch_environment(environment)&.state
          stop_environment(environment, deployment) if environment_state && environment_state != 'stopped'
        end

        delete_environment(environment, deployment) if deployed_at < delete_threshold

        checked_environments << environment.slug
      end

      delete_stopped_environments(environment_type: :docs_review_app, checked_environments: checked_environments, last_updated_threshold: delete_threshold)
    end

    def perform_helm_releases_cleanup!(days:)
      puts "Dry-run mode." if dry_run
      puts "Checking for Helm releases that are failed or not updated in the last #{days} days..."

      threshold = threshold_time(days: days)

      releases_to_delete = []

      helm_releases.each do |release|
        # Prevents deleting `dns-gitlab-review-app` releases or other unrelated releases
        next unless Tooling::KubernetesClient::K8S_ALLOWED_NAMESPACES_REGEX.match?(release.namespace)
        next unless release.name.start_with?('review-')

        if release.status == 'failed' || release.last_update < threshold
          releases_to_delete << release
        else
          print_release_state(subject: 'Release', release_name: release.name, release_date: release.last_update, action: 'leaving')
        end
      end

      delete_helm_releases(releases_to_delete)
    end

    def perform_stale_namespace_cleanup!(days:)
      puts "Dry-run mode." if dry_run

      kubernetes.cleanup_namespaces_by_created_at(created_before: threshold_time(days: days)) unless dry_run
    end

    private

    attr_reader :api_endpoint, :dry_run, :gitlab_token, :project_path

    def fetch_environment(environment)
      gitlab.environment(project_path, environment.id)
    rescue Errno::ETIMEDOUT => ex
      puts "Failed to fetch '#{environment.name}' / '#{environment.slug}' (##{environment.id}):\n#{ex.message}"
      nil
    end

    def delete_environment(environment, deployment = nil)
      release_date = deployment ? deployment.created_at : environment.updated_at
      print_release_state(subject: 'Review app', release_name: environment.slug, release_date: release_date, action: 'deleting')
      gitlab.delete_environment(project_path, environment.id) unless dry_run

    rescue Gitlab::Error::NotFound
      puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) was not found: ignoring it"
      @environments_not_found_count += 1

      if @environments_not_found_count >= ENVIRONMENTS_NOT_FOUND_THRESHOLD
        raise "At least #{ENVIRONMENTS_NOT_FOUND_THRESHOLD} environments were missing when we tried to delete them. Please investigate"
      end
    rescue Gitlab::Error::Forbidden
      puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) is forbidden: skipping it"
    rescue Gitlab::Error::InternalServerError
      puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) 500 error: ignoring it"
    end

    def stop_environment(environment, deployment)
      print_release_state(subject: 'Review app', release_name: environment.slug, release_date: deployment.created_at, action: 'stopping')
      gitlab.stop_environment(project_path, environment.id) unless dry_run

    rescue Gitlab::Error::Forbidden
      puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) is forbidden: skipping it"
    end

    def delete_stopped_environments(environment_type:, checked_environments:, last_updated_threshold:)
      gitlab.environments(project_path, per_page: DEPLOYMENTS_PER_PAGE, sort: 'desc', states: 'stopped', search: ENVIRONMENT_PREFIX[environment_type]).auto_paginate do |environment|
        next if skip_environment?(environment: environment, checked_environments: checked_environments, last_updated_threshold: last_updated_threshold, environment_type: environment_type)

        yield environment if delete_environment(environment) && block_given?

        checked_environments << environment.slug
      end
    end

    def skip_environment?(environment:, checked_environments:, last_updated_threshold:, environment_type:)
      return true unless environment.name.start_with?(ENVIRONMENT_PREFIX[environment_type])
      return true if checked_environments.include?(environment.slug)
      return true if Time.parse(environment.updated_at) > last_updated_threshold

      false
    end

    def helm_releases
      args = ['--all', '--all-namespaces', '--date']

      helm.releases(args: args)
    end

    def delete_helm_releases(releases)
      return if releases.empty?

      releases.each do |release|
        print_release_state(subject: 'Release', release_name: release.name, release_status: release.status, release_date: release.last_update, action: 'cleaning')
      end

      releases_names = releases.map(&:name)
      unless dry_run
        helm.delete(release_name: releases_names)
        kubernetes.delete_namespaces(releases_names)
      end

    rescue Tooling::Helm3Client::CommandFailedError => ex
      raise ex unless ignore_exception?(ex.message, IGNORED_HELM_ERRORS)

      puts "Ignoring the following Helm error:\n#{ex}\n"
    rescue Tooling::KubernetesClient::CommandFailedError => ex
      raise ex unless ignore_exception?(ex.message, IGNORED_KUBERNETES_ERRORS)

      puts "Ignoring the following Kubernetes error:\n#{ex}\n"
    end

    def threshold_time(days:)
      days_integer = days.to_i

      raise "days should be an integer between 1 and 365 inclusive! Got #{days_integer}" unless days_integer.between?(1, 365)

      Time.now - days_integer * 24 * 3600
    end

    def ignore_exception?(exception_message, exceptions_ignored)
      exception_message.match?(/(#{exceptions_ignored})/)
    end

    def print_release_state(subject:, release_name:, release_date:, action:, release_status: nil)
      puts "\n#{subject} '#{release_name}' #{"(#{release_status}) " if release_status}was last deployed on #{release_date}: #{action} it.\n"
    end
  end
end

def timed(task)
  start = Time.now
  yield(self)
  puts "#{task} finished in #{Time.now - start} seconds.\n"
end

if $PROGRAM_NAME == __FILE__
  options           = ReviewApps::AutomatedCleanup.parse_args(ARGV)
  automated_cleanup = ReviewApps::AutomatedCleanup.new(options: options)

  timed('Docs Review Apps cleanup') do
    automated_cleanup.perform_gitlab_docs_environment_cleanup!(days_for_stop: 20, days_for_delete: 30)
  end

  puts

  timed('Helm releases cleanup') do
    automated_cleanup.perform_helm_releases_cleanup!(days: 2)
  end

  puts

  timed('Review Apps cleanup') do
    automated_cleanup.perform_gitlab_environment_cleanup!(days_for_delete: 7)
  end

  puts

  timed('Stale Namespace cleanup') do
    automated_cleanup.perform_stale_namespace_cleanup!(days: 3)
  end
end
