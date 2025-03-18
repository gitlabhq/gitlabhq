# frozen_string_literal: true

class AddApprovalMergeRequestRulesApprovedApproversProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :approval_merge_request_rules_approved_approvers,
      sharding_key: :project_id,
      parent_table: :approval_merge_request_rules,
      parent_sharding_key: :project_id,
      foreign_key: :approval_merge_request_rule_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :approval_merge_request_rules_approved_approvers,
      sharding_key: :project_id,
      parent_table: :approval_merge_request_rules,
      parent_sharding_key: :project_id,
      foreign_key: :approval_merge_request_rule_id
    )
  end
end
