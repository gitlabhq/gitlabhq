# frozen_string_literal: true

class SchedulePurgingStaleSecurityScans < Gitlab::Database::Migration[2.0]
  MIGRATION = 'PurgeStaleSecurityScans'
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    return unless should_run?

    queue_background_migration_jobs_by_range_at_intervals(
      Gitlab::BackgroundMigration::PurgeStaleSecurityScans::SecurityScan.to_purge,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
