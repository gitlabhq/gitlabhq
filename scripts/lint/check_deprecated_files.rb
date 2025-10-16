#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'rainbow'

class CheckDeprecatedFiles
  FEEDBACK_ISSUE = "https://gitlab.com/gitlab-org/gitlab/-/issues/575249"
  DEFAULT_DEPRECATION_REGISTRY = "./config/lint/deprecations.yml"
  DEFAULT_BASE_BRANCH = "origin/master"

  attr_reader :deprecation_registry

  def initialize(deprecation_registry: DEFAULT_DEPRECATION_REGISTRY)
    @deprecation_registry = deprecation_registry
  end

  def execute!(modified_files = nil)
    terminate "#{deprecation_registry} not found" unless File.exist?(deprecation_registry)

    files_to_check = modified_files || modified_files_local

    modified_deprecated_files = files_to_check.select { |file| deprecated_files.include?(file) }
    exit 0 if modified_deprecated_files.empty?

    display_warning(modified_deprecated_files)
    exit 1
  end

  private

  def terminate(message)
    warn Rainbow("Error: #{message}").bright.red
    exit 1
  end

  def run(*cmd, quiet: false)
    stdout_str, stderr_str, status = Open3.capture3(*cmd)
    terminate "command failed: #{stderr_str}" unless quiet || status.success?
    stdout_str.chomp
  end

  def modified_files_local
    upstream = run("git rev-parse --abbrev-ref --symbolic-full-name @{u}", quiet: true)

    base_branch = if upstream && !upstream.empty?
                    upstream
                  else
                    DEFAULT_BASE_BRANCH
                  end

    merge_base = run("git", "merge-base", base_branch, "HEAD")
    modified_files = run("git", "diff", "--name-only", "#{merge_base}..HEAD")

    modified_files.split("\n").map(&:strip).reject(&:empty?)
  end

  def deprecated_files
    @deprecated_files ||= begin
      yaml_content = YAML.safe_load_file(deprecation_registry)
      yaml_content.fetch('files').flat_map { |entry| Array(entry['paths']) }.to_set
    end
  rescue StandardError => e
    terminate "Failed to parse #{deprecation_registry}: #{e.message}"
  end

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
    puts "  • Push with: #{Rainbow('LEFTHOOK_EXCLUDE=check-deprecated-files git push').bright.cyan}"
    puts
    puts "Deprecation Details: #{Rainbow(deprecation_registry).bright.green}"
    puts "Questions/Feedback: #{Rainbow(FEEDBACK_ISSUE).bright.green}"
    puts Rainbow("━" * 75).bright.red
  end
end

CheckDeprecatedFiles.new.execute! if __FILE__ == $PROGRAM_NAME
