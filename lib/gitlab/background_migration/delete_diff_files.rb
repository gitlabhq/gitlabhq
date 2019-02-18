# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeleteDiffFiles
      include Helpers::Reschedulable

      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'

        belongs_to :merge_request
        has_many :merge_request_diff_files
      end

      class MergeRequestDiffFile < ActiveRecord::Base
        self.table_name = 'merge_request_diff_files'
      end

      def perform(ids)
        @ids = ids

        reschedule_if_needed([ids]) do
          prune_diff_files
        end
      end

      private

      def should_reschedule?
        wait_for_deadtuple_vacuum?(MergeRequestDiffFile.table_name)
      end

      def diffs_collection
        MergeRequestDiff.where(id: @ids)
      end

      def prune_diff_files
        removed = 0
        updated = 0

        MergeRequestDiff.transaction do
          updated = diffs_collection.update_all(state: 'without_files')
          removed = MergeRequestDiffFile.where(merge_request_diff_id: @ids).delete_all
        end

        log_info("Removed #{removed} merge_request_diff_files rows, "\
                 "updated #{updated} merge_request_diffs rows")
      end

      def log_info(message)
        Rails.logger.info("BackgroundMigration::DeleteDiffFiles - #{message}")
      end
    end
  end
end
