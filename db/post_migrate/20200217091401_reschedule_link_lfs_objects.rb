# frozen_string_literal: true

class RescheduleLinkLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'LinkLfsObjects'
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  def up
    forks = Gitlab::BackgroundMigration::LinkLfsObjects::Project.with_non_existing_lfs_objects

    queue_background_migration_jobs_by_range_at_intervals(
      forks,
      MIGRATION,
      BackgroundMigrationWorker.minimum_interval,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # No-op. No need to make this reversible. In case the jobs enqueued runs and
    # fails at some point, some records will be created. When rescheduled, those
    # records won't be re-created. It's also hard to track which records to clean
    # up if ever.
  end
end
