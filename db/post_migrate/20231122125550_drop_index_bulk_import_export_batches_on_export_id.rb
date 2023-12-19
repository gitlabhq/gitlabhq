# frozen_string_literal: true

class DropIndexBulkImportExportBatchesOnExportId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_bulk_import_export_batches_on_export_id
  TABLE_NAME = :bulk_import_export_batches

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :export_id, name: INDEX_NAME
  end
end
