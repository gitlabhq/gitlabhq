# frozen_string_literal: true

class FinalizeHkBackfillProtectedEnvironmentApprovalRulesProtectedEnvir47878 < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedEnvironmentApprovalRulesProtectedEnvironmentGroupId',
      table_name: :protected_environment_approval_rules,
      column_name: :id,
      job_arguments: [:protected_environment_group_id, :protected_environments, :group_id, :protected_environment_id],
      finalize: true
    )
  end

  def down; end
end
