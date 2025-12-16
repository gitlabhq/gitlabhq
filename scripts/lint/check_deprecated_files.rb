#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'rainbow'

# Scans for modifications to deprecated files by comparing:
# - Local: commits against the upstream branch (or "origin/master" as fallback)
# - CI: changes in the merge request (using CI_MERGE_REQUEST_DIFF_BASE_SHA)
#
# YAML Configuration Structure (./config/lint/deprecations.yml):
#
# files:
#   - reason: "Migration to new architecture in progress"
#     feature_issue: https://gitlab.com/groups/gitlab-org/-/epics/54321
#     removal_issue: https://gitlab.com/gitlab-org/gitlab/-/issues/09876
#     feature_category: groups_and_projects
#     paths:
#       - app/assets/javascripts/legacy_component.js
#
# Usage:
#   Via lefthook (recommended): lefthook run pre-push --command check-deprecated-files
#   Direct execution: ./scripts/lint/check_deprecated_files.rb
#
# CI Environment Variables:
#   GitLab CI:
#     - CI_MERGE_REQUEST_DIFF_BASE_SHA: Base SHA for the merge request diff
#     - GITLAB_CI: Set when running in GitLab CI

class CheckDeprecatedFiles
  FEEDBACK_ISSUE = "https://gitlab.com/gitlab-org/gitlab/-/issues/575249"
  DEFAULT_DEPRECATION_REGISTRY = "./config/lint/deprecations.yml"
  DEFAULT_BASE_BRANCH = "origin/master"

  attr_reader :deprecation_registry

  def initialize(deprecation_registry: DEFAULT_DEPRECATION_REGISTRY)
    @deprecation_registry = deprecation_registry
  end

  def execute!(files = nil)
    terminate "#{deprecation_registry} not found" unless File.exist?(deprecation_registry)

    files_to_check = files || modified_files

    modified_deprecated_files = files_to_check.select { |file| deprecated_files.include?(file) }
    exit 0 if modified_deprecated_files.empty?

    display_warning(modified_deprecated_files)
    exit 1
  end

  private

  def ci?
    !!ENV['GITLAB_CI']
  end

  def terminate(message)
    warn Rainbow("Error: #{message}").bright.red
    exit 1
  end

  def run(*cmd, quiet: false)
    stdout_str, stderr_str, status = Open3.capture3(*cmd)
    terminate "command failed: #{stderr_str}" unless quiet || status.success?
    stdout_str.chomp
  end

  def modified_files
    base_sha = ci? ? base_sha_ci : base_sha_local

    files = run("git", "diff", "--name-only", "#{base_sha}..HEAD")
    files.split("\n").map(&:strip).reject(&:empty?)
  end

  def base_sha_local
    upstream = run("git rev-parse --abbrev-ref --symbolic-full-name @{u}", quiet: true)

    base_branch = if upstream && !upstream.empty?
                    upstream
                  else
                    DEFAULT_BASE_BRANCH
                  end

    run("git", "merge-base", base_branch, "HEAD")
  end

  def base_sha_ci
    ENV['CI_MERGE_REQUEST_DIFF_BASE_SHA']
  end

  def deprecated_files
    @deprecated_files ||= begin
      yaml_content = YAML.safe_load_file(deprecation_registry)&.fetch('files')
      Array(yaml_content).flat_map { |entry| Array(entry['paths']) }.to_set
    end
  rescue StandardError => e
    terminate "Failed to parse #{deprecation_registry}: #{e.message}"
  end

  # rubocop:disable Metrics/AbcSize -- AbcSize is high because of `Rainbow` calls but method has low complexity
  def display_warning(modified_deprecated_files)
    puts Rainbow("━" * 75).bright.red
    puts Rainbow("⚠️  WARNING: You are modifying deprecated files!  ⚠️").bright.red
    puts Rainbow("━" * 75).bright.red
    puts "The following deprecated files have been modified:"

    modified_deprecated_files.each do |file|
      puts "  #{Rainbow('•').bright.red} #{Rainbow(file).bright.red}"
    end

    puts
    puts "To proceed with this change:"
    puts "  • Get approval from a DRI (add as reviewer)"
    puts "  • Explain why this change is necessary in your MR"
    puts "  • Update #{Rainbow(deprecation_registry).bright.green} for removed/moved files"
    puts
    puts "To bypass this check:"

    if ci?
      puts "  • Add #{Rainbow('~"pipeline:skip-check-deprecated-files"').bright.cyan} label to your MR"
    else
      puts "  • Push with: #{Rainbow('LEFTHOOK_EXCLUDE=check-deprecated-files git push').bright.cyan}"
    end

    puts
    puts "Deprecation Details: #{Rainbow(deprecation_registry).bright.green}"
    puts "Questions/Feedback: #{Rainbow(FEEDBACK_ISSUE).bright.green}"
    puts Rainbow("━" * 75).bright.red
  end
  # rubocop:enable Metrics/AbcSize
end

CheckDeprecatedFiles.new.execute! if __FILE__ == $PROGRAM_NAME
