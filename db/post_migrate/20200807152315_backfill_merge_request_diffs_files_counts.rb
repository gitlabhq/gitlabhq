# frozen_string_literal: true

class BackfillMergeRequestDiffsFilesCounts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # There are ~72 million records on GitLab.com at time of writing, so go fast
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 2.minutes.to_i
  MIGRATION = 'SetMergeRequestDiffFilesCount'

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_request_diffs'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      MergeRequestDiff, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
