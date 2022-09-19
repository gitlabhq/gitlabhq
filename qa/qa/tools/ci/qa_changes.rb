# frozen_string_literal: true

require "pathname"

module QA
  module Tools
    module Ci
      # Determine specific qa specs or paths to execute based on changes
      class QaChanges
        include Helpers

        QA_PATTERN = %r{^qa/}.freeze
        SPEC_PATTERN = %r{^qa/qa/specs/features/}.freeze

        def initialize(mr_diff, mr_labels)
          @mr_diff = mr_diff
          @mr_labels = mr_labels
        end

        # Specific specs to run
        #
        # @return [String]
        def qa_tests
          return if mr_diff.empty?
          # make paths relative to qa directory
          return changed_files&.map { |path| path.delete_prefix("qa/") }&.join(" ") if only_spec_changes?
          return qa_spec_directories_for_devops_stage&.join(" ") if non_qa_changes? && mr_labels.any?
        end

        # Qa framework changes
        #
        # @return [Boolean]
        def framework_changes?
          return false if mr_diff.empty?
          return false if only_spec_changes?

          changed_files
            # TODO: expand pattern to other non spec paths that shouldn't trigger full suite
            .select { |file_path| file_path.match?(QA_PATTERN) && !file_path.match?(SPEC_PATTERN) }
            .any?
        end

        def quarantine_changes?
          return false if mr_diff.empty?
          return false if mr_diff.any? { |change| change[:new_file] || change[:deleted_file] }

          files_count = 0
          specs_count = 0
          quarantine_specs_count = 0

          mr_diff.each do |change|
            path = change[:path]
            next if File.directory?(File.expand_path("../#{path}", QA::Runtime::Path.qa_root))

            files_count += 1
            next unless path.match?(SPEC_PATTERN) && path.end_with?('_spec.rb')

            specs_count += 1
            quarantine_specs_count += 1 if change[:diff].match?(/^\+.*,? quarantine:/)
          end

          return false if specs_count == 0
          return true if quarantine_specs_count == specs_count && quarantine_specs_count == files_count

          false
        end

        private

        # @return [Array]
        attr_reader :mr_diff

        # @return [Array]
        attr_reader :mr_labels

        # Are the changed files only qa specs?
        #
        # @return [Boolean] whether the changes files are only qa specs
        def only_spec_changes?
          changed_files.all? { |file_path| file_path =~ SPEC_PATTERN }
        end

        # Are the changed files only outside the qa directory?
        #
        # @return [Boolean] whether the changes files are outside of qa directory
        def non_qa_changes?
          changed_files.none? { |file_path| file_path =~ QA_PATTERN }
        end

        # Extract devops stage from MR labels
        #
        # @return [String] a devops stage
        def devops_stage_from_mr_labels
          mr_labels.find { |label| label =~ /^devops::/ }&.delete_prefix('devops::')
        end

        # Get qa spec directories for devops stage
        #
        # @return [Array] qa spec directories
        def qa_spec_directories_for_devops_stage
          devops_stage = devops_stage_from_mr_labels
          return unless devops_stage

          Dir.glob("qa/specs/**/*/").select { |dir| dir =~ %r{\d+_#{devops_stage}/$} }
        end

        # Change files in merge request
        #
        # @return [Array<String>]
        def changed_files
          @changed_files ||= mr_diff.map { |change| change[:path] } # rubocop:disable Rails/Pluck
        end
      end
    end
  end
end
