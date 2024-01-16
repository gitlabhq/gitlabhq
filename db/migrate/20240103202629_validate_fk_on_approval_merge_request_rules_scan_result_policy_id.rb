# frozen_string_literal: true

class ValidateFkOnApprovalMergeRequestRulesScanResultPolicyId < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  NEW_CONSTRAINT_NAME = 'fk_approval_merge_request_rules_on_scan_result_policy_id'

  # foreign key added in db/migrate/20240103200822_replace_fk_on_approval_merge_request_rules_scan_result_policy_id.rb
  def up
    validate_foreign_key(:approval_merge_request_rules, :scan_result_policy_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
