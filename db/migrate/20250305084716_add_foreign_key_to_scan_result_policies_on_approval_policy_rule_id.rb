# frozen_string_literal: true

class AddForeignKeyToScanResultPoliciesOnApprovalPolicyRuleId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :scan_result_policies, :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade,
      validate: false
  end

  def down
    remove_foreign_key_if_exists :scan_result_policies, column: :approval_policy_rule_id
  end
end
