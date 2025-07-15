# frozen_string_literal: true

class AddApprovalPolicyActionIdxToApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :approval_merge_request_rules, :approval_policy_action_idx, :smallint, default: 0, null: false
  end
end
