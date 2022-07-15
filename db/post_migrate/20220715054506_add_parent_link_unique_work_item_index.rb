# frozen_string_literal: true

class AddParentLinkUniqueWorkItemIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_work_item_parent_links_on_work_item_id'
  OLD_INDEX_NAME = 'index_parent_links_on_work_item_id_and_work_item_parent_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :work_item_parent_links, :work_item_id, unique: true, name: INDEX_NAME
    remove_concurrent_index_by_name :work_item_parent_links, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :work_item_parent_links, [:work_item_id, :work_item_parent_id],
      unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :work_item_parent_links, INDEX_NAME
  end
end
