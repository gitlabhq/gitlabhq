# frozen_string_literal: true

class AddRuleIdxConstraintToScanResultPolicies < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "check_scan_result_policies_rule_idx_positive"

  def up
    add_check_constraint :scan_result_policies, "rule_idx IS NULL OR rule_idx >= 0", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :scan_result_policies, CONSTRAINT_NAME
  end
end
