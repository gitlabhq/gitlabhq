# frozen_string_literal: true

class QueueBackfillCiJobArtifactStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiJobArtifactStatesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_job_artifact_states,
      :job_artifact_id,
      :project_id,
      :p_ci_job_artifacts,
      :project_id,
      :job_artifact_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_job_artifact_states,
      :job_artifact_id,
      [
        :project_id,
        :p_ci_job_artifacts,
        :project_id,
        :job_artifact_id
      ]
    )
  end
end
