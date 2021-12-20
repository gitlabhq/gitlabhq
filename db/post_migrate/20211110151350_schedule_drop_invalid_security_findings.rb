# frozen_string_literal: true

class ScheduleDropInvalidSecurityFindings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = "DropInvalidSecurityFindings"
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 10_000

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('security_findings').where(uuid: nil),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      other_job_arguments: [SUB_BATCH_SIZE],
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
