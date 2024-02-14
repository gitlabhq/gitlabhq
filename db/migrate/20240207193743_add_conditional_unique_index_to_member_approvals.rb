# frozen_string_literal: true

class AddConditionalUniqueIndexToMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  INDEX_NAME = 'unique_member_approvals_on_pending_status'

  def up
    add_concurrent_index :member_approvals, [:member_id, :member_namespace_id, :new_access_level],
      unique: true, where: "status = 0", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :member_approvals, INDEX_NAME
  end
end
