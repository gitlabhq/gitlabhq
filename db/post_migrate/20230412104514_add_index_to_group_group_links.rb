# frozen_string_literal: true

class AddIndexToGroupGroupLinks < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_group_group_links_on_shared_with_group_and_group_access'
  TABLE_NAME = :group_group_links

  def up
    add_concurrent_index TABLE_NAME, [:shared_with_group_id, :group_access], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end
end
