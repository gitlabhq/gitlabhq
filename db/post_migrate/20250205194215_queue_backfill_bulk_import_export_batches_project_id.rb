# frozen_string_literal: true

class QueueBackfillBulkImportExportBatchesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillBulkImportExportBatchesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :bulk_import_export_batches,
      :id,
      :project_id,
      :bulk_import_exports,
      :project_id,
      :export_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :bulk_import_export_batches,
      :id,
      [
        :project_id,
        :bulk_import_exports,
        :project_id,
        :export_id
      ]
    )
  end
end
