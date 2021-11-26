# frozen_string_literal: true

class AddPolicyIdxToApprovalMergeRequestRule < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :approval_merge_request_rules, :orchestration_policy_idx, :integer, limit: 2
  end
end
