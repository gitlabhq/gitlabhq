# frozen_string_literal: true

class AddIndexToProjectGroupLinksOnMemberRoleId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME = 'index_project_group_links_on_member_role_id'

  def up
    add_concurrent_index :project_group_links, :member_role_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_group_links, INDEX_NAME
  end
end
