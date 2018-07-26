# frozen_string_literal: true

require 'gitlab'
require_relative File.expand_path('../../lib/quality/helm_client.rb', __dir__)
require_relative File.expand_path('../../lib/quality/kubernetes_client.rb', __dir__)

class AutomatedCleanup
  STALE_REVIEW_APP_DAYS_THRESHOLD = 10.freeze

  attr_reader :project_path, :gitlab_token, :cleaned_up_releases

  def initialize(project_path: ENV['CI_PROJECT_PATH'], gitlab_token: ENV['GITLAB_BOT_REVIEW_APPS_CLEANUP_TOKEN'])
    @project_path = project_path
    @gitlab_token = gitlab_token
    @cleaned_up_releases = []
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

  def helm
    @helm ||= Quality::HelmClient.new
  end

  def kubernetes
    @kubernetes ||= Quality::KubernetesClient.new
  end

  def perform_gitlab_environment_cleanup!(days_for_stop: STALE_REVIEW_APP_DAYS_THRESHOLD, days_for_delete: STALE_REVIEW_APP_DAYS_THRESHOLD)
    puts "Checking for review apps not updated in the last #{days_for_stop} days..."

    checked_environments = []
    gitlab.deployments(project_path, per_page: 50).auto_paginate do |deployment|
      next unless deployment.environment.name.start_with?('review/')
      next if checked_environments.include?(deployment.environment.slug)

      puts

      checked_environments << deployment.environment.slug
      deployed_at = Time.parse(deployment.created_at)

      if deployed_at < threshold_time(days: days_for_delete)
        print_release_state(subject: 'Review app', release_name: deployment.environment.slug, release_date: deployment.created_at, action: 'deleting')
        gitlab.delete_environment(project_path, deployment.environment.id)
        cleaned_up_releases << deployment.environment.slug
      elsif deployed_at < threshold_time(days: days_for_stop)
        print_release_state(subject: 'Review app', release_name: deployment.environment.slug, release_date: deployment.created_at, action: 'stopping')
        gitlab.stop_environment(project_path, deployment.environment.id)
        cleaned_up_releases << deployment.environment.slug
      else
        print_release_state(subject: 'Review app', release_name: deployment.environment.slug, release_date: deployment.created_at, action: 'leaving')
      end
    end
  end

  def perform_helm_releases_cleanup!(days: STALE_REVIEW_APP_DAYS_THRESHOLD)
    puts "Checking for Helm releases not updated in the last #{days} days..."

    helm.releases(args: ['--deployed', '--failed', '--date', '--reverse', '--max 25']).each do |release|
      next if cleaned_up_releases.include?(release.name)

      if release.last_update < threshold_time(days: days)
        print_release_state(subject: 'Release', release_name: release.name, release_date: release.last_update, action: 'cleaning')
        helm.delete(release_name: release.name)
        kubernetes.cleanup(release_name: release.name)
      else
        print_release_state(subject: 'Release', release_name: release.name, release_date: release.last_update, action: 'leaving')
      end
    end
  end

  def threshold_time(days:)
    Time.now - days * 24 * 3600
  end

  def print_release_state(subject:, release_name:, release_date:, action:)
    puts "\n#{subject} '#{release_name}' was last deployed on #{release_date}: #{action} it."
  end
end

def timed(task)
  start = Time.now
  yield(self)
  puts "#{task} finished in #{Time.now - start} seconds.\n"
end

automated_cleanup = AutomatedCleanup.new

timed('Review apps cleanup') do
  automated_cleanup.perform_gitlab_environment_cleanup!(days_for_stop: 5, days_for_delete: 6)
end

puts

timed('Helm releases cleanup') do
  automated_cleanup.perform_helm_releases_cleanup!(days: 7)
end

exit(0)
