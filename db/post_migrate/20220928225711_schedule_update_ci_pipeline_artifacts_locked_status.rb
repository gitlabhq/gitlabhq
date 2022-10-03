# frozen_string_literal: true

class ScheduleUpdateCiPipelineArtifactsLockedStatus < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION = 'UpdateCiPipelineArtifactsUnknownLockedStatus'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 500

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_pipeline_artifacts,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_pipeline_artifacts, :id, [])
  end
end
