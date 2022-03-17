# frozen_string_literal: true

class ScheduleNullifyOrphanRunnerIdOnCiBuilds < Gitlab::Database::Migration[1.0]
  MIGRATION = 'NullifyOrphanRunnerIdOnCiBuilds'
  INTERVAL = 2.minutes
  BATCH_SIZE = 50_000
  MAX_BATCH_SIZE = 150_000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_builds,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :ci_builds, :id, [])
      .delete_all
  end
end
