# frozen_string_literal: true

class AddApprovalPolicyIdConstraintToScanResultPolicyViolations < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  CONSTRAINT_NAME = "chk_policy_violations_rule_id_or_policy_id_not_null"

  def up
    add_check_constraint :scan_result_policy_violations,
      "approval_policy_rule_id IS NOT NULL OR scan_result_policy_id IS NOT NULL", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :scan_result_policy_violations, CONSTRAINT_NAME
  end
end
