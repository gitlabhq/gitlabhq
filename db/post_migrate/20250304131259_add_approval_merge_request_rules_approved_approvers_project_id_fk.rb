# frozen_string_literal: true

class AddApprovalMergeRequestRulesApprovedApproversProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_merge_request_rules_approved_approvers, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_merge_request_rules_approved_approvers, column: :project_id
    end
  end
end
