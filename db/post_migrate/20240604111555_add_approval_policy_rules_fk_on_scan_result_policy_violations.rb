# frozen_string_literal: true

class AddApprovalPolicyRulesFkOnScanResultPolicyViolations < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_scan_result_policy_violations_on_approval_policy_rule_id'

  def up
    add_concurrent_index :scan_result_policy_violations, :approval_policy_rule_id, name: INDEX_NAME
    add_concurrent_foreign_key :scan_result_policy_violations, :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :scan_result_policy_violations, column: :approval_policy_rule_id
    remove_concurrent_index_by_name :scan_result_policy_violations, INDEX_NAME
  end
end
