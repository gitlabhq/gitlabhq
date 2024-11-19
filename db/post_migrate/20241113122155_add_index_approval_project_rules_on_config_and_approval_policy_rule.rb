# frozen_string_literal: true

class AddIndexApprovalProjectRulesOnConfigAndApprovalPolicyRule < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  INDEX_NAME = :idx_approval_project_rules_on_config_id_and_policy_rule_id
  TABLE_NAME = :approval_project_rules

  def up
    add_concurrent_index(TABLE_NAME, %i[security_orchestration_policy_configuration_id approval_policy_rule_id],
      name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
