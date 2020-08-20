# frozen_string_literal: true

class ScheduleCopyOfMrTargetProjectIdToMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 5_000
  MIGRATION = 'CopyMergeRequestTargetProjectToMergeRequestMetrics'

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    MergeRequest.reset_column_information

    queue_background_migration_jobs_by_range_at_intervals(
      MergeRequest,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # noop
  end
end
