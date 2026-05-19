# frozen_string_literal: true

class FinalizeHkBackfillPCiPipelineArtifactStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPCiPipelineArtifactStatesProjectId',
      table_name: :p_ci_pipeline_artifact_states,
      column_name: :pipeline_artifact_id,
      job_arguments: [:project_id, :ci_pipeline_artifacts, :project_id, :pipeline_artifact_id],
      finalize: true
    )
  end

  def down; end
end
