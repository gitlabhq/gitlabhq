# frozen_string_literal: true

class AddBatchForeignKeyToBulkImportExportUploads < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_export_uploads, :bulk_import_export_batches, column: :batch_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :bulk_import_export_uploads, column: :batch_id
    end
  end
end
