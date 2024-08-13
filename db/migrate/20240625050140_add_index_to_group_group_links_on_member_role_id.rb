# frozen_string_literal: true

class AddIndexToGroupGroupLinksOnMemberRoleId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_group_group_links_on_member_role_id'

  def up
    add_concurrent_index :group_group_links, :member_role_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :group_group_links, INDEX_NAME
  end
end
