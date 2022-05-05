# frozen_string_literal: true

class RecreateIndexForGroupGroupLinkWithBothGroupIds < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_group_group_links_on_shared_with_group_id'
  NEW_INDEX_NAME = 'index_group_group_links_on_shared_with_group_and_shared_group'

  def up
    add_concurrent_index :group_group_links, [:shared_with_group_id, :shared_group_id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :group_group_links, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :group_group_links, [:shared_with_group_id], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :group_group_links, NEW_INDEX_NAME
  end
end
