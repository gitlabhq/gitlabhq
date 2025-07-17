# frozen_string_literal: true

class AddApprovalMergeRequestRulesApprovedApproversProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :approval_merge_request_rules_approved_approvers, :project_id
  end

  def down
    remove_not_null_constraint :approval_merge_request_rules_approved_approvers, :project_id
  end
end
