# frozen_string_literal: true

class FinalizeBackfillDeploymentMergeRequestsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDeploymentMergeRequestsProjectId',
      table_name: :deployment_merge_requests,
      column_name: :deployment_id,
      job_arguments: [:project_id, :deployments, :project_id, :deployment_id],
      finalize: true
    )
  end

  def down; end
end
