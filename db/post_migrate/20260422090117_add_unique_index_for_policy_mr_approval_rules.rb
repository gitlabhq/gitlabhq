# frozen_string_literal: true

class AddUniqueIndexForPolicyMrApprovalRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  INDEX_NAME = 'idx_unique_approval_mr_rules_for_scan_result_policy'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/620
    add_concurrent_index :approval_merge_request_rules,
      [:merge_request_id, :name, :rule_type, :security_orchestration_policy_configuration_id,
        :orchestration_policy_idx, :approval_policy_action_idx],
      unique: true,
      where: 'report_type IN (2, 4, 5)',
      name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end
