# frozen_string_literal: true

class ValidateFkOnApprovalMergeRequestRulesApprovalPolicyRuleId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  NEW_CONSTRAINT_NAME = 'fk_approval_merge_request_rules_on_approval_policy_rule_id'

  # foreign key added in db/migrate/20240918130318_replace_fk_on_approval_merge_request_rules_approval_policy_rule_id.rb
  def up
    validate_foreign_key(:approval_merge_request_rules, :approval_policy_rule_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
