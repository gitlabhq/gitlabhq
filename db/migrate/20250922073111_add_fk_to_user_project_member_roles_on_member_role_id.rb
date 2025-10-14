# frozen_string_literal: true

class AddFkToUserProjectMemberRolesOnMemberRoleId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_project_member_roles, :member_roles, column: :member_role_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_project_member_roles, column: :member_role_id
    end
  end
end
