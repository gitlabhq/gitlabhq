# frozen_string_literal: true

class FinalizeHkBackfillProtectedEnvironmentDeployAccessLevelsProtected8203 < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedEnvironmentDeployAccessLevelsProtectedEnvironmentGroupId',
      table_name: :protected_environment_deploy_access_levels,
      column_name: :id,
      job_arguments: [:protected_environment_group_id, :protected_environments, :group_id, :protected_environment_id],
      finalize: true
    )
  end

  def down; end
end
