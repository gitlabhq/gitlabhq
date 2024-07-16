#!/usr/bin/env ruby

# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require 'optparse'

module Packages
  class AutomatedCleanup
    PACKAGES_PER_PAGE = 100

    # $GITLAB_PROJECT_PACKAGES_CLEANUP_API_TOKEN => `Packages Cleanup` project token
    def initialize(
      project_path: ENV['CI_PROJECT_PATH'],
      gitlab_token: ENV['GITLAB_PROJECT_PACKAGES_CLEANUP_API_TOKEN'],
      api_endpoint: ENV['CI_API_V4_URL'],
      options: {}
    )
      @project_path = project_path
      @gitlab_token = gitlab_token
      @api_endpoint = api_endpoint
      @dry_run = options[:dry_run]

      puts "Dry-run mode." if dry_run
    end

    def gitlab
      @gitlab ||= begin
        Gitlab.configure do |config|
          config.endpoint = api_endpoint
          config.private_token = gitlab_token
        end

        Gitlab
      end
    end

    def perform_gitlab_package_cleanup!(package_name:, days_for_delete:)
      puts "Checking for '#{package_name}' packages created at least #{days_for_delete} days ago..."

      gitlab.project_packages(project_path,
        package_type: 'generic',
        package_name: package_name,
        per_page: PACKAGES_PER_PAGE).auto_paginate do |package|
        next unless package.name == package_name # the search is fuzzy, so we better check the actual package name

        if old_enough(package, days_for_delete) && not_recently_downloaded(package, days_for_delete)
          delete_package(package)
        end
      end
    end

    private

    attr_reader :project_path, :gitlab_token, :api_endpoint, :dry_run

    def delete_package(package)
      print_package_state(package)
      gitlab.delete_project_package(project_path, package.id) unless dry_run
    rescue Gitlab::Error::Forbidden
      puts "Package #{package_full_name(package)} is forbidden: skipping it"
    end

    def time_ago(days:)
      Time.now - (days * 24 * 3600)
    end

    def old_enough(package, days_for_delete)
      Time.parse(package.created_at) < time_ago(days: days_for_delete)
    end

    def not_recently_downloaded(package, days_for_delete)
      package.last_downloaded_at.nil? ||
        Time.parse(package.last_downloaded_at) < time_ago(days: days_for_delete)
    end

    def print_package_state(package)
      download_text =
        if package.last_downloaded_at
          "last downloaded on #{package.last_downloaded_at}"
        else
          "never downloaded"
        end

      puts "\nPackage #{package_full_name(package)} (created on #{package.created_at}) was " \
        "#{download_text}: deleting it.\n"
    end

    def package_full_name(package)
      "'#{package.name}/#{package.version}'"
    end
  end
end

def timed(task)
  start = Time.now
  yield(self)
  puts "#{task} finished in #{Time.now - start} seconds.\n"
end

if $PROGRAM_NAME == __FILE__
  options = {
    dry_run: false
  }

  OptionParser.new do |opts|
    opts.on("-d", "--dry-run", "Whether to perform a dry-run or not.") do |value|
      options[:dry_run] = true
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  automated_cleanup = Packages::AutomatedCleanup.new(options: options)

  timed('"gitlab-workhorse" packages cleanup') do
    automated_cleanup.perform_gitlab_package_cleanup!(package_name: 'gitlab-workhorse', days_for_delete: 30)
  end

  timed('"assets" packages cleanup') do
    automated_cleanup.perform_gitlab_package_cleanup!(package_name: 'assets', days_for_delete: 7)
  end

  timed('"fixtures" packages cleanup') do
    automated_cleanup.perform_gitlab_package_cleanup!(package_name: 'fixtures', days_for_delete: 14)
  end
end
