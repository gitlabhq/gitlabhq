# frozen_string_literal: true

class FinalizeHkBackfillCiJobArtifactStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiJobArtifactStatesProjectId',
      table_name: :ci_job_artifact_states,
      column_name: :job_artifact_id,
      job_arguments: [:project_id, :p_ci_job_artifacts, :project_id, :job_artifact_id],
      finalize: true
    )
  end

  def down; end
end
