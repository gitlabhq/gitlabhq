# frozen_string_literal: true

class AddBatchIdIndexToBulkImportExportUploads < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'bulk_import_export_uploads_batch_id'

  def up
    add_concurrent_index :bulk_import_export_uploads, :batch_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :bulk_import_export_uploads, :batch_id, name: INDEX_NAME
  end
end
