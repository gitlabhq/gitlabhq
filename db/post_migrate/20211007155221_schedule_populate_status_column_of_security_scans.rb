# frozen_string_literal: true

class SchedulePopulateStatusColumnOfSecurityScans < Gitlab::Database::Migration[1.0]
  MIGRATION = 'PopulateStatusColumnOfSecurityScans'
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('security_scans'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
