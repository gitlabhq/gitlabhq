# frozen_string_literal: true

class StartBackfillCiQueuingTables < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillCiQueuingTables'
  BATCH_SIZE = 500
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    return if Gitlab.com?

    queue_background_migration_jobs_by_range_at_intervals(
      Gitlab::BackgroundMigration::BackfillCiQueuingTables::Ci::Build.pending,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true)
  end

  def down
    # no-op
  end
end
