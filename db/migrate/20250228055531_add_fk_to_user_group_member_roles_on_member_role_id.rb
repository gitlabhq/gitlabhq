# frozen_string_literal: true

class AddFkToUserGroupMemberRolesOnMemberRoleId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key :user_group_member_roles, :member_roles, column: :member_role_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_group_member_roles, column: :member_role_id
    end
  end
end
