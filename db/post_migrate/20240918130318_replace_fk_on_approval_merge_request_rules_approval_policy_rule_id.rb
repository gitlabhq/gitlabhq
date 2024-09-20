# frozen_string_literal: true

class ReplaceFkOnApprovalMergeRequestRulesApprovalPolicyRuleId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  NEW_CONSTRAINT_NAME = 'fk_approval_merge_request_rules_on_approval_policy_rule_id'

  def up
    add_concurrent_foreign_key(
      :approval_merge_request_rules,
      :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :nullify,
      validate: false,
      name: NEW_CONSTRAINT_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:approval_merge_request_rules,
        column: :approval_policy_rule_id,
        on_delete: :nullify,
        name: NEW_CONSTRAINT_NAME)
    end
  end
end
