# frozen_string_literal: true

class AddApprovalPolicyActionIdxToApprovalProjectRules < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.7'

  def change
    add_column :approval_project_rules, :approval_policy_action_idx, :smallint, default: 0, null: false
  end
end
