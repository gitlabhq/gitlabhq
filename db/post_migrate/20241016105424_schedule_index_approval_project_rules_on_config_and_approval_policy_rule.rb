# frozen_string_literal: true

class ScheduleIndexApprovalProjectRulesOnConfigAndApprovalPolicyRule < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = :idx_approval_project_rules_on_config_id_and_policy_rule_id
  TABLE_NAME = :approval_project_rules
  COLUMNS = %i[security_orchestration_policy_configuration_id approval_policy_rule_id]

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
