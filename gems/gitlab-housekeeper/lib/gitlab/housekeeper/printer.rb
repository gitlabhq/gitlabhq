# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string'
require 'amazing_print'

module Gitlab
  module Housekeeper
    class Printer
      def initialize(logger:, dry_run: false)
        @logger = logger
        @dry_run = dry_run
      end

      def running_keep(keep_class)
        logger.puts "Running keep #{keep_class}"
      end

      def invalid_change(keep_class, identifiers)
        logger.warn "Ignoring invalid change from #{keep_class} with identifier #{identifiers}"
      end

      def skipped_by_filter(identifiers)
        logger.puts "Skipping change: #{identifiers} due to not matching filter."
      end

      def skipped_closed_merge_request(identifiers, branch_name)
        logger.puts "Skipping change: #{identifiers} as we have closed an MR for this branch #{branch_name}"
      end

      def aborted(branch_name)
        logger.puts "Skipping change as it is marked aborted."
        logger.puts "Modified files have been committed to branch " \
                    "#{AmazingPrint::Colors.yellowish(branch_name)}, but will not be pushed."
        logger.puts
      end

      def change_details(change, branch_name, diff)
        base_message = "Merge request URL: #{change.mr_web_url || '(known after create)'}, on branch #{branch_name}. " \
                       "Squash commits enabled."
        base_message << " CI skipped." if change.push_options.ci_skip

        logger.puts AmazingPrint::Colors.yellowish(base_message)
        logger.puts AmazingPrint::Colors.purple("=> #{change.identifiers.join(': ')}")

        logger.puts AmazingPrint::Colors.purple('=> Title:')
        logger.puts AmazingPrint::Colors.purple(change.title)
        logger.puts

        logger.puts '=> Description:'
        logger.puts change.mr_description
        logger.puts

        print_attributes(change)

        logger.puts '=> Diff:'
        logger.puts diff
        logger.puts
      end

      def completion(mrs_created_count)
        mr_count_string = "#{mrs_created_count} #{'MR'.pluralize(mrs_created_count)}"

        message = if dry_run
                    "Dry run complete. Housekeeper would have created #{mr_count_string} on an actual run."
                  else
                    "Housekeeper created #{mr_count_string}."
                  end

        logger.puts AmazingPrint::Colors.yellowish(message)
        logger.puts
      end

      private

      attr_reader :logger, :dry_run

      def print_attributes(change)
        return unless change.labels.present? || change.assignees.present? || change.reviewers.present?

        logger.puts '=> Attributes:'
        logger.puts "Labels: #{change.labels.join(', ')}"
        logger.puts "Assignees: #{change.assignees.join(', ')}"
        logger.puts "Reviewers: #{change.reviewers.join(', ')}"
        logger.puts
      end
    end
  end
end
