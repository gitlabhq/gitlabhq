# frozen_string_literal: true

class QueueMigrateOsSbomOccurrencesToComponentsWithoutPrefix < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  # We only want to run once the migration that removes the prefix
  # has completed. This migration then moves all the occurrences
  # to the components that have the correct prefix.
  DEPENDENT_BACKGROUND_MIGRATIONS = %w[20240425205205]

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "MigrateOsSbomOccurrencesToComponentsWithoutPrefix"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 2000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_components,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_components, :id, [])
  end
end
