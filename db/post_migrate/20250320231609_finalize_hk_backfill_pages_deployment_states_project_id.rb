# frozen_string_literal: true

class FinalizeHkBackfillPagesDeploymentStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPagesDeploymentStatesProjectId',
      table_name: :pages_deployment_states,
      column_name: :pages_deployment_id,
      job_arguments: [:project_id, :pages_deployments, :project_id, :pages_deployment_id],
      finalize: true
    )
  end

  def down; end
end
