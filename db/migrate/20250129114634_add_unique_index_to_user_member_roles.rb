# frozen_string_literal: true

class AddUniqueIndexToUserMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  DOWNTIME = false
  OLD_INDEX_NAME = 'idx_user_member_roles_on_user_id'
  NEW_INDEX_NAME = 'idx_user_member_roles_on_user_id_unique'

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_member_roles, :user_id, unique: true, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :user_member_roles, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :user_member_roles, :user_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :user_member_roles, NEW_INDEX_NAME
  end
end
