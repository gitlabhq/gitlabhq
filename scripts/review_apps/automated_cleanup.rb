# frozen_string_literal: true

require 'gitlab'
require_relative File.expand_path('../../tooling/lib/tooling/helm3_client.rb', __dir__)
require_relative File.expand_path('../../tooling/lib/tooling/kubernetes_client.rb', __dir__)

class AutomatedCleanup
  attr_reader :project_path, :gitlab_token

  DEPLOYMENTS_PER_PAGE = 100
  IGNORED_HELM_ERRORS = [
    'transport is closing',
    'error upgrading connection',
    'not found'
  ].freeze
  IGNORED_KUBERNETES_ERRORS = [
    'NotFound'
  ].freeze

  def self.ee?
    # Support former project name for `dev`
    %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME'])
  end

  # $GITLAB_PROJECT_REVIEW_APP_CLEANUP_API_TOKEN => `Automated Review App Cleanup` project token
  def initialize(project_path: ENV['CI_PROJECT_PATH'], gitlab_token: ENV['GITLAB_PROJECT_REVIEW_APP_CLEANUP_API_TOKEN'])
    @project_path = project_path
    @gitlab_token = gitlab_token
  end

  def gitlab
    @gitlab ||= begin
      Gitlab.configure do |config|
        config.endpoint = 'https://gitlab.com/api/v4'
        # gitlab-bot's token "GitLab review apps cleanup"
        config.private_token = gitlab_token
      end

      Gitlab
    end
  end

  def review_apps_namespace
    'review-apps'
  end

  def helm
    @helm ||= Tooling::Helm3Client.new(namespace: review_apps_namespace)
  end

  def kubernetes
    @kubernetes ||= Tooling::KubernetesClient.new(namespace: review_apps_namespace)
  end

  def perform_gitlab_environment_cleanup!(days_for_stop:, days_for_delete:)
    puts "Checking for Review Apps not updated in the last #{days_for_stop} days..."

    checked_environments = []
    delete_threshold = threshold_time(days: days_for_delete)
    stop_threshold = threshold_time(days: days_for_stop)
    deployments_look_back_threshold = threshold_time(days: days_for_delete * 5)

    releases_to_delete = []

    gitlab.deployments(project_path, per_page: DEPLOYMENTS_PER_PAGE, sort: 'desc').auto_paginate do |deployment|
      break if Time.parse(deployment.created_at) < deployments_look_back_threshold

      environment = deployment.environment

      next unless environment
      next unless environment.name.start_with?('review/')
      next if checked_environments.include?(environment.slug)

      last_deploy = deployment.created_at
      deployed_at = Time.parse(last_deploy)

      if deployed_at < delete_threshold
        deleted_environment = delete_environment(environment, deployment)
        if deleted_environment
          release = Tooling::Helm3Client::Release.new(environment.slug, 1, deployed_at.to_s, nil, nil, review_apps_namespace)
          releases_to_delete << release
        end
      else
        if deployed_at >= stop_threshold
          print_release_state(subject: 'Review App', release_name: environment.slug, release_date: last_deploy, action: 'leaving')
        else
          environment_state = fetch_environment(environment)&.state
          stop_environment(environment, deployment) if environment_state && environment_state != 'stopped'
        end
      end

      checked_environments << environment.slug
    end

    delete_helm_releases(releases_to_delete)
  end

  def perform_helm_releases_cleanup!(days:)
    puts "Checking for Helm releases that are failed or not updated in the last #{days} days..."

    threshold = threshold_time(days: days)

    releases_to_delete = []

    helm_releases.each do |release|
      # Prevents deleting `dns-gitlab-review-app` releases or other unrelated releases
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
    kubernetes_client = Tooling::KubernetesClient.new(namespace: nil)

    kubernetes_client.cleanup_review_app_namespaces(created_before: threshold_time(days: days), wait: false)
  end

  def perform_stale_pvc_cleanup!(days:)
    kubernetes.cleanup_by_created_at(resource_type: 'pvc', created_before: threshold_time(days: days), wait: false)
  end

  private

  def fetch_environment(environment)
    gitlab.environment(project_path, environment.id)
  rescue Errno::ETIMEDOUT => ex
    puts "Failed to fetch '#{environment.name}' / '#{environment.slug}' (##{environment.id}):\n#{ex.message}"
    nil
  end

  def delete_environment(environment, deployment)
    print_release_state(subject: 'Review app', release_name: environment.slug, release_date: deployment.created_at, action: 'deleting')
    gitlab.delete_environment(project_path, environment.id)

  rescue Gitlab::Error::Forbidden
    puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) is forbidden: skipping it"
  end

  def stop_environment(environment, deployment)
    print_release_state(subject: 'Review app', release_name: environment.slug, release_date: deployment.created_at, action: 'stopping')
    gitlab.stop_environment(project_path, environment.id)

  rescue Gitlab::Error::Forbidden
    puts "Review app '#{environment.name}' / '#{environment.slug}' (##{environment.id}) is forbidden: skipping it"
  end

  def helm_releases
    args = ['--all', '--date']

    helm.releases(args: args)
  end

  def delete_helm_releases(releases)
    return if releases.empty?

    releases.each do |release|
      print_release_state(subject: 'Release', release_name: release.name, release_status: release.status, release_date: release.last_update, action: 'cleaning')
    end

    releases_names = releases.map(&:name)
    helm.delete(release_name: releases_names)
    kubernetes.cleanup_by_release(release_name: releases_names, wait: false)

  rescue Tooling::Helm3Client::CommandFailedError => ex
    raise ex unless ignore_exception?(ex.message, IGNORED_HELM_ERRORS)

    puts "Ignoring the following Helm error:\n#{ex}\n"
  rescue Tooling::KubernetesClient::CommandFailedError => ex
    raise ex unless ignore_exception?(ex.message, IGNORED_KUBERNETES_ERRORS)

    puts "Ignoring the following Kubernetes error:\n#{ex}\n"
  end

  def threshold_time(days:)
    Time.now - days * 24 * 3600
  end

  def ignore_exception?(exception_message, exceptions_ignored)
    exception_message.match?(/(#{exceptions_ignored})/)
  end

  def print_release_state(subject:, release_name:, release_date:, action:, release_status: nil)
    puts "\n#{subject} '#{release_name}' #{"(#{release_status}) " if release_status}was last deployed on #{release_date}: #{action} it.\n"
  end
end

def timed(task)
  start = Time.now
  yield(self)
  puts "#{task} finished in #{Time.now - start} seconds.\n"
end

automated_cleanup = AutomatedCleanup.new

timed('Review Apps cleanup') do
  automated_cleanup.perform_gitlab_environment_cleanup!(days_for_stop: 5, days_for_delete: 6)
end

puts

timed('Helm releases cleanup') do
  automated_cleanup.perform_helm_releases_cleanup!(days: 7)
end

timed('Stale Namespace cleanup') do
  automated_cleanup.perform_stale_namespace_cleanup!(days: 14)
end

timed('Stale PVC cleanup') do
  automated_cleanup.perform_stale_pvc_cleanup!(days: 30)
end

exit(0)
