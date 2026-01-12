# frozen_string_literal: true

class AddUniqueIndexForOfflineExportsOnBulkImportExportsProjects < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_bulk_import_exports_on_project_relation_offline_export'

  def up
    add_concurrent_index :bulk_import_exports,
      %i[project_id relation offline_export_id],
      unique: true,
      name: INDEX_NAME,
      where: 'project_id IS NOT NULL AND offline_export_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :bulk_import_exports, INDEX_NAME
  end
end
