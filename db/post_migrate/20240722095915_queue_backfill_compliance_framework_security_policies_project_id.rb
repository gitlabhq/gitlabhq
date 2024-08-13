# frozen_string_literal: true

class QueueBackfillComplianceFrameworkSecurityPoliciesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillComplianceFrameworkSecurityPoliciesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :compliance_framework_security_policies,
      :id,
      :project_id,
      :security_orchestration_policy_configurations,
      :project_id,
      :policy_configuration_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :compliance_framework_security_policies,
      :id,
      [
        :project_id,
        :security_orchestration_policy_configurations,
        :project_id,
        :policy_configuration_id
      ]
    )
  end
end
