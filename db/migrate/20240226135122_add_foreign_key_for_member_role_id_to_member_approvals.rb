# frozen_string_literal: true

class AddForeignKeyForMemberRoleIdToMemberApprovals < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_concurrent_foreign_key :member_approvals, :member_roles, column: :member_role_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :member_approvals, column: :member_role_id
    end
  end
end
