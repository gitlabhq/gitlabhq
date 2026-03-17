# frozen_string_literal: true

class QueueBackfillPCiPipelineArtifactStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPCiPipelineArtifactStatesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :p_ci_pipeline_artifact_states,
      :pipeline_artifact_id,
      :project_id,
      :ci_pipeline_artifacts,
      :project_id,
      :pipeline_artifact_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :p_ci_pipeline_artifact_states,
      :pipeline_artifact_id,
      [
        :project_id,
        :ci_pipeline_artifacts,
        :project_id,
        :pipeline_artifact_id
      ]
    )
  end
end
