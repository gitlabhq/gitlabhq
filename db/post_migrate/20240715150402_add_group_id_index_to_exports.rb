# frozen_string_literal: true

class AddGroupIdIndexToExports < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAME = :group_id
  INDEX_NAME = 'index_bulk_import_exports_on_group_id'

  def up
    add_concurrent_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
