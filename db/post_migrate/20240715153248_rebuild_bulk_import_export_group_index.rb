# frozen_string_literal: true

class RebuildBulkImportExportGroupIndex < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAMES = [:group_id, :relation, :user_id]
  INDEX_NAME = 'partial_idx_bulk_import_exports_on_group_user_and_relation'
  CONSTRAINT = 'group_id IS NOT NULL AND user_id IS NOT NULL'

  def up
    add_concurrent_index(TABLE_NAME, COLUMN_NAMES, unique: true, name: INDEX_NAME, where: CONSTRAINT)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
