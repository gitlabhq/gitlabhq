# frozen_string_literal: true

class AddApprovalRuleIdToDeploymentApprovals < Gitlab::Database::Migration[1.0]
  def change
    add_column :deployment_approvals, :approval_rule_id, :bigint
  end
end
