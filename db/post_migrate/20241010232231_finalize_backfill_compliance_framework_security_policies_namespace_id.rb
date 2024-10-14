# frozen_string_literal: true

class FinalizeBackfillComplianceFrameworkSecurityPoliciesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillComplianceFrameworkSecurityPoliciesNamespaceId',
      table_name: :compliance_framework_security_policies,
      column_name: :id,
      job_arguments: [:namespace_id, :security_orchestration_policy_configurations, :namespace_id,
        :policy_configuration_id],
      finalize: true
    )
  end

  def down; end
end
