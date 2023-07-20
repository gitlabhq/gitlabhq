# frozen_string_literal: true

class AddRuleIdxToScanResultPolicies < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  CONSTRAINT_NAME = "check_scan_result_policies_rule_idx_positive"

  def up
    add_column :scan_result_policies, :rule_idx, :smallint
  end

  def down
    remove_column :scan_result_policies, :rule_idx
  end
end
