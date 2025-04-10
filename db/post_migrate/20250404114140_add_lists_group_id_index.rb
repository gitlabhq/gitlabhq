# frozen_string_literal: true

class AddListsGroupIdIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_lists_on_group_id'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_index :lists, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :lists, :group_id, name: INDEX_NAME
  end
end
