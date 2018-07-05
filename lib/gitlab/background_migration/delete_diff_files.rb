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

      BATCH = 5_000
      DEAD_TUPLES_THRESHOLD = 50_000
      VACUUM_WAIT_TIME = 5.minutes

      def perform
        diffs_with_files = MergeRequestDiff
          .joins(:merge_request)
          .where("merge_requests.state = 'merged'")
          .where('merge_requests.latest_merge_request_diff_id IS NOT NULL')
          .where('merge_requests.latest_merge_request_diff_id != merge_request_diffs.id')
          .where("merge_request_diffs.state NOT IN ('without_files', 'empty')")

        diffs_with_files.each_batch(of: BATCH) do |batch, index|
          wait_deadtuple_vacuum(index)
          prune_diff_files(batch, index)
        end
      end

      def wait_deadtuple_vacuum(index)
        db_klass = Gitlab::Database

        if defined?(db_klass) && db_klass.respond_to?(:postgresql?) && db_klass.postgresql?
          while diff_files_dead_tuples_count >= DEAD_TUPLES_THRESHOLD
            log_info("Dead tuple threshold hit on merge_request_diff_files (#{index}th batch): " \
                     "#{diff_files_dead_tuples_count}, waiting 5 minutes")
            sleep VACUUM_WAIT_TIME
          end
        end
      end

      private

      def diff_files_dead_tuples_count
        dead_tuple =
          execute_statement("SELECT n_dead_tup FROM pg_stat_all_tables "\
                            "WHERE relname = 'merge_request_diff_files'")[0]

        if dead_tuple.present?
          dead_tuple['n_dead_tup'].to_i
        else
          0
        end
      end

      def prune_diff_files(batch, index)
        diff_ids = batch.pluck(:id)

        removed = 0
        updated = 0

        MergeRequestDiff.transaction do
          updated = MergeRequestDiff.where(id: diff_ids)
            .update_all(state: 'without_files')
          removed = MergeRequestDiffFile.where(merge_request_diff_id: diff_ids)
            .delete_all
        end

        log_info("#{index}th batch - Removed #{removed} merge_request_diff_files rows, "\
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
