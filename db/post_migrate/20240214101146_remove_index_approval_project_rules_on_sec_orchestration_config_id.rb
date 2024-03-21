# frozen_string_literal: true

class RemoveIndexApprovalProjectRulesOnSecOrchestrationConfigId < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  TABLE_NAME = :approval_project_rules
  INDEX_NAME = :idx_approval_project_rules_on_sec_orchestration_config_id

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :security_orchestration_policy_configuration_id, name: INDEX_NAME)
  end
end
