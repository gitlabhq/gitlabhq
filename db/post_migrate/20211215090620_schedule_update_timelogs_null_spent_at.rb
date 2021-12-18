# frozen_string_literal: true

class ScheduleUpdateTimelogsNullSpentAt < Gitlab::Database::Migration[1.0]
  DOWNTIME = false
  BATCH_SIZE = 5_000
  DELAY_INTERVAL = 2.minutes
  MIGRATION = 'UpdateTimelogsNullSpentAt'

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('timelogs').where(spent_at: nil),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
