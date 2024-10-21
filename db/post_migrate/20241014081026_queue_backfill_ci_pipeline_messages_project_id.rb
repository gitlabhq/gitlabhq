# frozen_string_literal: true

class QueueBackfillCiPipelineMessagesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiPipelineMessagesProjectId"
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_pipeline_messages,
      :id,
      :project_id,
      :p_ci_pipelines,
      :project_id,
      :pipeline_id,
      :partition_id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_pipeline_messages,
      :id,
      [
        :project_id,
        :p_ci_pipelines,
        :project_id,
        :pipeline_id,
        :partition_id
      ]
    )
  end
end
