# frozen_string_literal: true

class QueueBackfillBulkImportTrackersShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillBulkImportTrackersShardingKey"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :bulk_import_trackers,
      :id,
      batch_size: BATCH_SIZE,
      job_interval: DELAY_INTERVAL,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :bulk_import_trackers, :id, [])
  end
end
