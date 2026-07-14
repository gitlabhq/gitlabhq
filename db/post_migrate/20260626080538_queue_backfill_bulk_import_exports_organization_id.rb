# frozen_string_literal: true

class QueueBackfillBulkImportExportsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillBulkImportExportsOrganizationId"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :bulk_import_exports,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :bulk_import_exports, :id, [])
  end
end
