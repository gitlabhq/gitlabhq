# frozen_string_literal: true

class RemoveOldBulkImportExportProjectIndex < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_exports
  OLD_COLUMN_NAMES = [:project_id, :relation]
  OLD_INDEX_NAME = 'partial_index_bulk_import_exports_on_project_id_and_relation'
  OLD_CONSTRAINT = 'project_id IS NOT NULL'

  def up
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, OLD_COLUMN_NAMES, unique: true, name: OLD_INDEX_NAME, where: OLD_CONSTRAINT)
  end
end
