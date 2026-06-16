# frozen_string_literal: true

class AddIndexToBulkImportExportsOnOfflineExportIdAndStatus < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_import_exports_on_offline_export_id_and_status'

  def up
    add_concurrent_index :bulk_import_exports,
      [:offline_export_id, :status],
      where: 'offline_export_id IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_exports, INDEX_NAME
  end
end
