# frozen_string_literal: true

class AddIndexForMemberApprovalsMemberNamespaceIdStatus < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  INDEX_NAME = 'index_member_approvals_on_member_namespace_id_status'

  def up
    add_concurrent_index :member_approvals, [:member_namespace_id, :status], where: 'status = 0', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :member_approvals, INDEX_NAME
  end
end
