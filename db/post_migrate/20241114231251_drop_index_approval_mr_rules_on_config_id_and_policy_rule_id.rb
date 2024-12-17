# frozen_string_literal: true

class DropIndexApprovalMrRulesOnConfigIdAndPolicyRuleId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_approval_mr_rules_on_config_id_and_policy_rule_id'

  disable_ddl_transaction!
  milestone '17.7'

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules,
      %w[security_orchestration_policy_configuration_id approval_policy_rule_id], name: INDEX_NAME
  end
end
