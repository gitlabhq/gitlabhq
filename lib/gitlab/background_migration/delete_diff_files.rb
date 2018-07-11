# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeleteDiffFiles
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'

        belongs_to :merge_request
        has_many :merge_request_diff_files
      end

      class MergeRequestDiffFile < ActiveRecord::Base
        self.table_name = 'merge_request_diff_files'
      end

      DEAD_TUPLES_THRESHOLD = 50_000
      VACUUM_WAIT_TIME = 5.minutes

      def perform(ids)
        @ids = ids

        # We should reschedule until deadtuples get in a desirable
        # state (e.g. < 50_000). That may take more than one reschedule.
        #
        if should_wait_deadtuple_vacuum?
          reschedule
          return
        end

        prune_diff_files
      end

      def should_wait_deadtuple_vacuum?
        return false unless Gitlab::Database.postgresql?

        diff_files_dead_tuples_count >= DEAD_TUPLES_THRESHOLD
      end

      private

      def reschedule
        BackgroundMigrationWorker.perform_in(VACUUM_WAIT_TIME, self.class.name.demodulize, [@ids])
      end

      def diffs_collection
        MergeRequestDiff.where(id: @ids)
      end

      def diff_files_dead_tuples_count
        dead_tuple =
          execute_statement("SELECT n_dead_tup FROM pg_stat_all_tables "\
                            "WHERE relname = 'merge_request_diff_files'")[0]

        dead_tuple&.fetch('n_dead_tup', 0).to_i
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

      def execute_statement(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def log_info(message)
        Rails.logger.info("BackgroundMigration::DeleteDiffFiles - #{message}")
      end
    end
  end
end
