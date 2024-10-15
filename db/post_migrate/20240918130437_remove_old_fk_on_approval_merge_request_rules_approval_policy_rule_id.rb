# frozen_string_literal: true

class RemoveOldFkOnApprovalMergeRequestRulesApprovalPolicyRuleId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  OLD_CONSTRAINT_NAME = 'fk_73fec3d7e5'

  # new foreign key added in
  # db/migrate/20240918130318_replace_fk_on_approval_merge_request_rules_approval_policy_rule_id.rb
  # and validated in db/migrate/20240918130409_validate_fk_on_approval_merge_request_rules_approval_policy_rule_id.rb
  def up
    remove_foreign_key_if_exists(
      :approval_merge_request_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade,
      name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :approval_merge_request_rules,
      :approval_policy_rules,
      column: :approval_policy_rule_id,
      on_delete: :cascade,
      validate: true,
      name: OLD_CONSTRAINT_NAME)
  end
end
