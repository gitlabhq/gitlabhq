#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'fileutils'
require 'rainbow/refinement'

module Lint
  class ValidateFastSpecHelperUsage
    using Rainbow

    SPEC_HELPER_PATTERN = /^require ['"]spec_helper['"]/
    FAST_SPEC_HELPER = "require 'fast_spec_helper'"

    attr_reader :target_branch, :can_use_fast_helper

    def initialize(target_branch: nil)
      @target_branch = target_branch || ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || 'master'
      @can_use_fast_helper = []
    end

    def run
      print_start_message

      newly_added_files = find_newly_added_spec_files
      if newly_added_files.empty?
        puts Rainbow("No newly added spec files found. Nothing to validate. ✓").green unless from_lefthook?
        return true
      end

      spec_helper_files = filter_spec_helper_files(newly_added_files)
      validate_specs(spec_helper_files)
    end

    private

    def from_lefthook?
      %w[1 true].include?(ENV['FROM_LEFTHOOK'])
    end

    def print_start_message
      return if from_lefthook?

      puts Rainbow("\nValidating newly added specs can use fast_spec_helper...").cyan
      puts
    end

    def find_newly_added_spec_files
      unless from_lefthook?
        puts Rainbow("Finding newly added spec files compared to #{target_branch}...").blue
        puts
      end

      # Get list of newly added spec files (A = added)
      cmd = "git diff --name-only --diff-filter=A $(git merge-base origin/#{target_branch} HEAD)..HEAD -- " \
        "'spec/**/*_spec.rb' 'ee/spec/**/*_spec.rb'"
      stdout, stderr, status = Open3.capture3(cmd)

      unless status.success?
        warn Rainbow("Warning: git diff command failed: #{stderr}").red
        return []
      end

      stdout.split("\n").reject(&:empty?)
    end

    def filter_spec_helper_files(files)
      files.select do |file|
        next unless File.exist?(file)

        content = File.read(file)
        content.match?(SPEC_HELPER_PATTERN)
      end
    end

    def validate_specs(files)
      if files.empty?
        puts Rainbow("No newly added spec files using spec_helper found. ✓").green unless from_lefthook?
        return true
      end

      unless from_lefthook?
        puts Rainbow("Found #{files.size} newly added spec file(s) using spec_helper").blue
        puts
      end

      files.each.with_index(1) do |file, index|
        puts "[#{index}/#{files.size}] Testing #{file}..." unless from_lefthook?

        if test_with_fast_spec_helper(file)
          puts Rainbow("  ✓ Can use fast_spec_helper").yellow unless from_lefthook?
          @can_use_fast_helper << file
        else
          puts Rainbow("  ✓ Requires spec_helper").green unless from_lefthook?
        end

        puts unless from_lefthook?
      end

      if @can_use_fast_helper.any?
        print_failure_message
        return false
      end

      print_success_message
      true
    end

    def test_with_fast_spec_helper(file)
      temp_file = "#{file}.tmp"

      begin
        # Create a temporary version with fast_spec_helper
        content = File.read(file)
        modified_content = content.sub(SPEC_HELPER_PATTERN, FAST_SPEC_HELPER)
        File.write(temp_file, modified_content)

        # Run the spec
        cmd = "bundle exec rspec #{temp_file} --format progress --fail-fast"
        stdout, _stderr, status = Open3.capture3(cmd)

        # Check if tests passed (0 failures)
        status.success? && stdout.include?('0 failures')
      ensure
        FileUtils.rm_f(temp_file)
      end
    end

    def print_failure_message
      puts
      puts Rainbow("========================================").red
      puts Rainbow("VALIDATION FAILED").red
      puts Rainbow("========================================").red
      puts

      puts "The following #{@can_use_fast_helper.size} spec file(s) can use " \
        "#{Rainbow('fast_spec_helper').yellow} instead of #{Rainbow('spec_helper').red}:"
      puts

      @can_use_fast_helper.each do |file|
        puts "  - #{file}"
      end

      puts
      puts Rainbow("Action required:").yellow
      puts "Please update these files to use 'fast_spec_helper' instead of 'spec_helper'."
      puts "This will improve test performance by avoiding unnecessary Rails environment loading."
      puts
      puts "To fix, replace:"
      puts "  #{Rainbow("require 'spec_helper'").red}"
      puts "with:"
      puts "  #{Rainbow("require 'fast_spec_helper'").green}"
      puts
    end

    def print_success_message
      return if from_lefthook? # Silent success for lefthook

      puts Rainbow("========================================").green
      puts Rainbow("VALIDATION PASSED ✓").green
      puts Rainbow("========================================").green
      puts
      puts "All newly added specs correctly use the appropriate spec helper."
    end
  end
end

if $PROGRAM_NAME == __FILE__
  validator = Lint::ValidateFastSpecHelperUsage.new
  success = validator.run
  exit(success ? 0 : 1)
end
