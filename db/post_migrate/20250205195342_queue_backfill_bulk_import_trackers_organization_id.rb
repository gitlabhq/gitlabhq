# frozen_string_literal: true

class QueueBackfillBulkImportTrackersOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillBulkImportTrackersOrganizationId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :bulk_import_trackers,
      :id,
      :organization_id,
      :bulk_import_entities,
      :organization_id,
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
        :organization_id,
        :bulk_import_entities,
        :organization_id,
        :bulk_import_entity_id
      ]
    )
  end
end
