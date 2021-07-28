# frozen_string_literal: true

class RescheduleDeleteOrphanedDeployments < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'DeleteOrphanedDeployments'
  BATCH_SIZE = 10_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)
    Gitlab::Database::BackgroundMigrationJob.for_migration_class(MIGRATION).delete_all

    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('deployments'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
