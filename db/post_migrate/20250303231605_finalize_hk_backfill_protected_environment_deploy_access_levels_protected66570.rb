# frozen_string_literal: true

class FinalizeHkBackfillProtectedEnvironmentDeployAccessLevelsProtected66570 < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedEnvironmentDeployAccessLevelsProtectedEnvironmentProjectId',
      table_name: :protected_environment_deploy_access_levels,
      column_name: :id,
      job_arguments: [:protected_environment_project_id, :protected_environments, :project_id,
        :protected_environment_id],
      finalize: true
    )
  end

  def down; end
end
