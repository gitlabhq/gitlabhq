# frozen_string_literal: true

class UpdateUserGroupMemberRolesIndexes < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'unique_user_group_member_roles_all_ids'
  OLD_INDEX_COLUMNS = %i[user_id group_id shared_with_group_id member_role_id]

  def up
    remove_concurrent_index_by_name :user_group_member_roles, name: OLD_INDEX_NAME

    add_concurrent_index :user_group_member_roles, :user_id,
      name: 'index_user_group_member_roles_on_user_id'

    add_concurrent_index :user_group_member_roles, %i[user_id group_id],
      name: 'unique_user_group_member_roles_user_group', unique: true,
      where: 'shared_with_group_id IS NULL'

    add_concurrent_index :user_group_member_roles, %i[user_id group_id shared_with_group_id],
      name: 'unique_user_group_member_roles_user_group_shared_with_group',
      unique: true, where: 'shared_with_group_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :user_group_member_roles,
      name: 'index_user_group_member_roles_on_user_id',
      if_exists: true

    remove_concurrent_index_by_name :user_group_member_roles,
      name: 'unique_user_group_member_roles_user_group',
      if_exists: true

    remove_concurrent_index_by_name :user_group_member_roles,
      name: 'unique_user_group_member_roles_user_group_shared_with_group',
      if_exists: true

    add_concurrent_index :user_group_member_roles, OLD_INDEX_COLUMNS,
      name: OLD_INDEX_NAME, unique: true
  end
end
