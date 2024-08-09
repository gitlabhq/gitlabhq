# frozen_string_literal: true

class AddIndexToMemberRolesOnPermissions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = 'index_member_roles_on_permissions'

  def up
    add_concurrent_index :member_roles, :permissions, name: INDEX_NAME, using: :gin
  end

  def down
    remove_concurrent_index_by_name :member_roles, INDEX_NAME
  end
end
