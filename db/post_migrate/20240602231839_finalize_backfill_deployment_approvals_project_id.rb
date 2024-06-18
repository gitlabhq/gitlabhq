# frozen_string_literal: true

class FinalizeBackfillDeploymentApprovalsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDeploymentApprovalsProjectId',
      table_name: :deployment_approvals,
      column_name: :id,
      job_arguments: [:project_id, :deployments, :project_id, :deployment_id],
      finalize: true
    )
  end

  def down; end
end
