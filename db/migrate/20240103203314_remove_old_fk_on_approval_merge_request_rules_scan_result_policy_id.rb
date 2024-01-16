# frozen_string_literal: true

class RemoveOldFkOnApprovalMergeRequestRulesScanResultPolicyId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  OLD_CONSTRAINT_NAME = 'fk_f726c79756'

  # new foreign key added in
  # db/migrate/20240103200822_replace_fk_on_approval_merge_request_rules_scan_result_policy_id.rb
  # and validated in db/migrate/20240103202629_validate_fk_on_approval_merge_request_rules_scan_result_policy_id.rb
  def up
    remove_foreign_key_if_exists(
      :approval_merge_request_rules,
      column: :scan_result_policy_id,
      on_delete: :cascade,
      name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :approval_merge_request_rules,
      :scan_result_policies,
      column: :scan_result_policy_id,
      on_delete: :cascade,
      validate: false,
      name: OLD_CONSTRAINT_NAME)
  end
end
