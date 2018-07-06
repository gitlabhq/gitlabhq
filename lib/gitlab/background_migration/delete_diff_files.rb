# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeleteDiffFiles
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'

        belongs_to :merge_request
        has_many :merge_request_diff_files

        include EachBatch
      end

      class MergeRequestDiffFile < ActiveRecord::Base
        self.table_name = 'merge_request_diff_files'

        include EachBatch
      end

      DIFF_ROWS_LIMIT = 5_000
      DEAD_TUPLES_THRESHOLD = 50_000
      VACUUM_WAIT_TIME = 5.minutes

      def perform
        rescheduling do
          prune_diff_files(diffs_collection.limit(DIFF_ROWS_LIMIT))
        end
      end

      def should_wait_deadtuple_vacuum?
        return false unless Gitlab::Database.postgresql?

        diff_files_dead_tuples_count >= DEAD_TUPLES_THRESHOLD
      end

      private

      def rescheduling(&block)
        # We should reschedule until deadtuples get in a desirable
        # state (e.g. < 50_000). That may take move than one reschedule.
        #
        if should_wait_deadtuple_vacuum?
          reschedule
          return
        end

        block.call

        reschedule if diffs_collection.limit(1).count > 0
      end

      def reschedule
        BackgroundMigrationWorker.perform_in(VACUUM_WAIT_TIME, self.class.name.demodulize)
      end

      def diffs_collection
        MergeRequestDiff
          .joins(:merge_request)
          .where("merge_requests.state = 'merged'")
          .where('merge_requests.latest_merge_request_diff_id IS NOT NULL')
          .where('merge_requests.latest_merge_request_diff_id != merge_request_diffs.id')
          .where("merge_request_diffs.state NOT IN ('without_files', 'empty')")
      end

      def diff_files_dead_tuples_count
        dead_tuple =
          execute_statement("SELECT n_dead_tup FROM pg_stat_all_tables "\
                            "WHERE relname = 'merge_request_diff_files'")[0]

        dead_tuple&.fetch('n_dead_tup', 0).to_i
      end

      def prune_diff_files(batch)
        diff_ids = batch.pluck(:id)

        removed = 0
        updated = 0

        MergeRequestDiff.transaction do
          updated = MergeRequestDiff.where(id: diff_ids)
            .update_all(state: 'without_files')
          removed = MergeRequestDiffFile.where(merge_request_diff_id: diff_ids)
            .delete_all
        end

        log_info("Removed #{removed} merge_request_diff_files rows, "\
                 "updated #{updated} merge_request_diffs rows")
      end

      def execute_statement(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def log_info(message)
        Rails.logger.info("BackgroundMigration::DeleteDiffFiles - #{message}")
      end
    end
  end
end
