# frozen_string_literal: true

class AddIndexApprovalMrRulesOnProjectIdPolicyRuleIdAndId < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  INDEX_NAME = :index_approval_mr_rules_on_project_id_policy_rule_id_and_id
  TABLE_NAME = :approval_merge_request_rules

  def up
    add_concurrent_index(TABLE_NAME, %i[security_orchestration_policy_configuration_id approval_policy_rule_id id],
      name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
