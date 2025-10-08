# frozen_string_literal: true

class AddUserProjectMemberRolesIdxUserProjectSharedWithGroup < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_project_member_roles, %i[user_id project_id shared_with_group_id],
      name: 'uniq_user_project_member_roles_user_project_shared_with_group', unique: true,
      where: 'shared_with_group_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :user_project_member_roles,
      name: 'uniq_user_project_member_roles_user_project_shared_with_group',
      if_exists: true
  end
end
