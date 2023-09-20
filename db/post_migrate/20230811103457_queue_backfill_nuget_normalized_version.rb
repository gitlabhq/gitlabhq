# frozen_string_literal: true

class QueueBackfillNugetNormalizedVersion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillNugetNormalizedVersion"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 6000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_nuget_metadata,
      :package_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_nuget_metadata, :package_id, [])
  end
end
