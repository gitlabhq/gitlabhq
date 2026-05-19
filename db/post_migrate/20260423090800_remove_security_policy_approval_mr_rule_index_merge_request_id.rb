# frozen_string_literal: true

class RemoveSecurityPolicyApprovalMrRuleIndexMergeRequestId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  INDEX_NAME = 'security_policy_approval_mr_rule_index_merge_request_id'

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules, :merge_request_id,
      name: INDEX_NAME,
      where: 'report_type = ANY (ARRAY[4, 2, 5])'
  end
end
