# frozen_string_literal: true

class UpdateIndexesOnMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'unique_member_approvals_on_pending_status'
  NEW_INDEX_NAME = 'unique_idx_member_approvals_on_pending_status'

  def up
    remove_concurrent_index_by_name :member_approvals, OLD_INDEX_NAME

    add_concurrent_index :member_approvals, [:user_id, :member_namespace_id, :new_access_level],
      unique: true, where: "status = 0", name: NEW_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :member_approvals, NEW_INDEX_NAME

    add_concurrent_index :member_approvals, [:member_id, :member_namespace_id, :new_access_level],
      unique: true, where: "status = 0", name: OLD_INDEX_NAME
  end
end
