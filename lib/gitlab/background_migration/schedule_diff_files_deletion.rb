# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ScheduleDiffFilesDeletion
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'

        has_many :merge_request_diff_files

        include EachBatch
      end

      ITERATION_BATCH = 1000
      DELETION_BATCH = 1000 # per minute
      MIGRATION = 'DeleteDiffFiles'

      # Considering query times and Redis writings, this should take around 2
      # hours to complete.
      def perform
        diffs_with_files = MergeRequestDiff.where.not(state: %w(without_files empty))

        # This will be increased for each scheduled job
        process_job_in = 1.second

        # explain (analyze, buffers) example for the iteration:
        #
        # Index Only Scan using tmp_index_20013 on merge_request_diffs  (cost=0.43..1630.19 rows=60567 width=4) (actual time=0.047..9.572 rows=56976 loops=1)
        #   Index Cond: ((id >= 764586) AND (id < 835298))
        #   Heap Fetches: 8
        #   Buffers: shared hit=18188
        # Planning time: 0.752 ms
        # Execution time: 12.430 ms
        #
        diffs_with_files.reorder(nil).each_batch(of: ITERATION_BATCH) do |relation, scheduler_index|
          relation.each do |diff|
            BackgroundMigrationWorker.perform_in(process_job_in, MIGRATION, [diff.id])

            diff_files_count = diff.merge_request_diff_files.reorder(nil).count

            # We should limit on 1000 diff files deletion per minute to avoid
            # replication lag issues.
            #
            interval = (diff_files_count.to_f / DELETION_BATCH).minutes
            process_job_in += interval
          end
        end

        log_days_to_process_all_jobs(process_job_in)
      end

      def log_days_to_process_all_jobs(seconds_to_process)
        days_to_process_all_jobs = (seconds_to_process / 60 / 60 / 24).to_i
        Rails.logger.info("Gitlab::BackgroundMigration::DeleteDiffFiles will take " \
                          "#{days_to_process_all_jobs} days to be processed")
      end
    end
  end
end
