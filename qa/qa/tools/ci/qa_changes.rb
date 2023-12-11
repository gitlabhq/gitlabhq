# frozen_string_literal: true

require "pathname"

module QA
  module Tools
    module Ci
      # Determine specific qa specs or paths to execute based on changes
      class QaChanges
        include Helpers

        QA_PATTERN = %r{^qa/}
        SPEC_PATTERN = %r{^qa/qa/specs/features/\S+_spec\.rb}
        DEPENDENCY_PATTERN = Regexp.union(
          /_VERSION/,
          /Gemfile\.lock/,
          /yarn\.lock/,
          /Dockerfile\.assets/
        )

        def initialize(mr_diff, mr_labels, additional_group_spec_list)
          @mr_diff = mr_diff
          @mr_labels = mr_labels
          @additional_group_spec_list = additional_group_spec_list
        end

        # Specific specs to run
        #
        # @return [String]
        def qa_tests
          return if mr_diff.empty? || dependency_changes
          return if only_spec_changes? && mr_diff.all? { |change| change[:deleted_file] }

          if only_spec_changes?
            return mr_diff
              .reject { |change| change[:deleted_file] }
              .map { |change| change[:path].delete_prefix("qa/") } # make paths relative to qa directory
              .join(" ")
          end

          qa_spec_directories_for_devops_stage&.join(" ") if non_qa_changes? && mr_labels.any?
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

        # @return [Hash<String, Array<String>>]
        attr_reader :additional_group_spec_list

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

        # Extract group name from MR labels
        #
        # @return [String] a group name
        def group_name_from_mr_labels
          mr_labels.find { |label| label =~ /^group::/ }&.delete_prefix('group::')
        end

        # Get qa spec directories for devops stage
        #
        # @return [Array] qa spec directories
        def qa_spec_directories_for_devops_stage
          devops_stage = devops_stage_from_mr_labels
          return unless devops_stage

          spec_dirs = stage_specs(devops_stage)
          return if spec_dirs.empty?

          grp_name = group_name_from_mr_labels
          return spec_dirs if grp_name.nil?

          additional_grp_specs = additional_group_spec_list[grp_name]
          return spec_dirs if additional_grp_specs.nil?

          spec_dirs + stage_specs(*additional_grp_specs)
        end

        # Changes to gitlab dependencies
        #
        # @return [Boolean]
        def dependency_changes
          changed_files.any? { |file| file.match?(DEPENDENCY_PATTERN) }
        end

        # Change files in merge request
        #
        # @return [Array<String>]
        def changed_files
          @changed_files ||= mr_diff.map { |change| change[:path] }
        end

        # Devops stage specs
        #
        # @param [Array<String>] devops_stages
        # @return [Array]
        def stage_specs(*devops_stages)
          Dir.glob("qa/specs/features/**/*/").select { |dir| dir =~ %r{\d+_(#{devops_stages.join('|')})/$} }
        end
      end
    end
  end
end
