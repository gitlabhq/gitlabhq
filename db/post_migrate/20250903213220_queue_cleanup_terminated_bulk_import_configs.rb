# frozen_string_literal: true

class QueueCleanupTerminatedBulkImportConfigs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "CleanupTerminatedBulkImportConfigs"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :bulk_imports,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    # no op
  end
end
