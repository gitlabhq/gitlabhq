# frozen_string_literal: true

class IndexScanResultPoliciesOnApprovalPolicyRuleId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_scan_result_policies_on_approval_policy_rule_id'

  def up
    add_concurrent_index :scan_result_policies, :approval_policy_rule_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :scan_result_policies, INDEX_NAME
  end
end
