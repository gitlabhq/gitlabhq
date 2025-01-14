# frozen_string_literal: true

class IndexBulkImportExportUploadsOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_import_export_uploads_on_group_id'

  def up
    add_concurrent_index :bulk_import_export_uploads, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_export_uploads, INDEX_NAME
  end
end
