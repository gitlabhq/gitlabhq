# frozen_string_literal: true

class AddIsNullClauseToPartialIdxBulkImportExportsOnProjectUserAndRelation < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  TABLE_NAME = 'bulk_import_exports'
  OLD_INDEX_NAME = 'partial_idx_bulk_import_exports_on_project_user_and_relation'
  NEW_INDEX_NAME = 'partial_idx_bulk_import_exports_on_project_user_relation'

  def up
    add_concurrent_index :bulk_import_exports,
      %i[project_id relation user_id],
      unique: true,
      name: NEW_INDEX_NAME,
      where: 'project_id IS NOT NULL AND user_id IS NOT NULL AND offline_export_id IS NULL'

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index :bulk_import_exports,
      %i[project_id relation user_id],
      unique: true,
      name: OLD_INDEX_NAME,
      where: 'project_id IS NOT NULL AND user_id IS NOT NULL'

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
