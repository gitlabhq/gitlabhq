# frozen_string_literal: true

class RemoveApprovalMergeRequestRulesApprovalPolicyRuleIdFk < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_approval_merge_request_rules_on_approval_policy_rule_id"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:approval_merge_request_rules, :approval_policy_rules,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:approval_merge_request_rules, :approval_policy_rules,
      name: FOREIGN_KEY_NAME, column: :approval_policy_rule_id,
      target_column: :id, on_delete: :nullify)
  end
end
