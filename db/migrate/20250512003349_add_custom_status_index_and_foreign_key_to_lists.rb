# frozen_string_literal: true

class AddCustomStatusIndexAndForeignKeyToLists < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_lists_on_custom_status_id'

  def up
    add_concurrent_index :lists, :custom_status_id, name: INDEX_NAME
    add_concurrent_foreign_key :lists, :work_item_custom_statuses, column: :custom_status_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :lists, column: :custom_status_id
    remove_concurrent_index_by_name :lists, INDEX_NAME
  end
end
