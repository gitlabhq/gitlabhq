# frozen_string_literal: true

class FinalizeHkBackfillScanResultPoliciesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillScanResultPoliciesProjectId',
      table_name: :scan_result_policies,
      column_name: :id,
      job_arguments: [:project_id, :security_orchestration_policy_configurations, :project_id,
        :security_orchestration_policy_configuration_id],
      finalize: true
    )
  end

  def down; end
end
