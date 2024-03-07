# frozen_string_literal: true

class AddMemberRoleIdToMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    add_column :member_approvals, :member_role_id, :bigint
    add_concurrent_index :member_approvals, :member_role_id
  end

  def down
    remove_column :member_approvals, :member_role_id
  end
end
