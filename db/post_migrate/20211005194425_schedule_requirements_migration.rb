# frozen_string_literal: true

class ScheduleRequirementsMigration < Gitlab::Database::Migration[1.0]
  DOWNTIME = false

  # 2021-10-05 requirements count: ~12500
  #
  # Using 30 as batch size and 120 seconds default interval will produce:
  # ~420 jobs - taking ~14 hours to perform
  BATCH_SIZE = 30

  MIGRATION = 'MigrateRequirementsToWorkItems'

  disable_ddl_transaction!

  class Requirement < ActiveRecord::Base
    include EachBatch

    self.table_name = 'requirements'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Requirement.where(issue_id: nil),
      MIGRATION,
      2.minutes,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # NO OP
  end
end
