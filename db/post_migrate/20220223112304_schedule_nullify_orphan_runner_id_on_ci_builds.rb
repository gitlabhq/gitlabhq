# frozen_string_literal: true

class ScheduleNullifyOrphanRunnerIdOnCiBuilds < Gitlab::Database::Migration[1.0]
  MIGRATION = 'NullifyOrphanRunnerIdOnCiBuilds'
  INTERVAL = 2.minutes
  BATCH_SIZE = 100_000
  MAX_BATCH_SIZE = 25_000 # 100k * 25k = 2.5B ci_builds
  SUB_BATCH_SIZE = 1_000

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
