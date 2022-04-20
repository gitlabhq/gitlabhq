# frozen_string_literal: true

class PopulateContainerRepositoriesMigrationPlan < Gitlab::Database::Migration[1.0]
  MIGRATION = 'PopulateContainerRepositoryMigrationPlan'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 1500

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('container_repositories'),
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
