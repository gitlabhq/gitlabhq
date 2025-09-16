# frozen_string_literal: true

class FinalizeHkBackfillSecurityOrchestrationPolicyRuleSchedulesProject < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSecurityOrchestrationPolicyRuleSchedulesProjectId',
      table_name: :security_orchestration_policy_rule_schedules,
      column_name: :id,
      job_arguments: [:project_id, :security_orchestration_policy_configurations, :project_id,
        :security_orchestration_policy_configuration_id],
      finalize: true
    )
  end

  def down; end
end
