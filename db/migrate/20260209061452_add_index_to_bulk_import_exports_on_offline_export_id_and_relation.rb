# frozen_string_literal: true

class AddIndexToBulkImportExportsOnOfflineExportIdAndRelation < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_exports
  NEW_INDEX_NAME = 'index_bulk_import_exports_on_offline_export_id_and_relation'
  OLD_INDEX_NAME = 'index_bulk_import_exports_on_offline_export_id'

  def up
    add_concurrent_index TABLE_NAME, [:offline_export_id, :relation], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
    add_concurrent_index TABLE_NAME, :offline_export_id, name: OLD_INDEX_NAME
  end
end
