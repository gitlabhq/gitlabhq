# frozen_string_literal: true

class RequeueBackfillBulkImportTrackersNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillBulkImportTrackersNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    begin
      delete_batched_background_migration(
        MIGRATION,
        :bulk_import_trackers,
        :id,
        [
          :namespace_id,
          :bulk_import_entities,
          :namespace_id,
          :bulk_import_entity_id
        ]
      )
    rescue StandardError => e
      # NOTE: It's possible that the BBM was already cleaned as it has been finalized before the requeue.
      #       We can safely ignore this failure.
      Gitlab::AppLogger.warn("Failed to delete batched background migration: #{e.message}")
    end

    queue_batched_background_migration(
      MIGRATION,
      :bulk_import_trackers,
      :id,
      :namespace_id,
      :bulk_import_entities,
      :namespace_id,
      :bulk_import_entity_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :bulk_import_trackers,
      :id,
      [
        :namespace_id,
        :bulk_import_entities,
        :namespace_id,
        :bulk_import_entity_id
      ]
    )
  end
end
