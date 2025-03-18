# frozen_string_literal: true

class AddProjectIdToApprovalMergeRequestRulesApprovedApprovers < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :approval_merge_request_rules_approved_approvers, :project_id, :bigint
  end
end
