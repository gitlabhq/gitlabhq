# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching strategy for BackfillMergeRequestDiffCommitsToPartitioned.
      #
      # On GitLab.com the BBM records use view names (merge_request_diff_commits_views_N) as
      # their table_name for parallelism tracking, but PostgreSQL cannot collapse row-style
      # (multi-column) index conditions through a view, causing full scans that are slower.
      # We override next_batch to ignore table_name and query merge_request_diff_commits directly;
      # the cursor bounds on each BBM record isolate the range for each parallel worker.
      class BackfillMergeRequestDiffCommitsToPartitionedBatchingStrategy < PrimaryKeyBatchingStrategy
        SOURCE_TABLE = 'merge_request_diff_commits'

        def next_batch(_table_name, column_name, batch_min_value:, batch_size:, job_arguments:, job_class: nil)
          super(SOURCE_TABLE, column_name, batch_min_value: batch_min_value, batch_size: batch_size,
                                           job_arguments: job_arguments, job_class: job_class)
        end
      end
    end
  end
end
