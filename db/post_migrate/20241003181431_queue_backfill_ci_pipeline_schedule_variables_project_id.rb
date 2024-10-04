# frozen_string_literal: true

class QueueBackfillCiPipelineScheduleVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiPipelineScheduleVariablesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_pipeline_schedule_variables,
      :id,
      :project_id,
      :ci_pipeline_schedules,
      :project_id,
      :pipeline_schedule_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_pipeline_schedule_variables,
      :id,
      [
        :project_id,
        :ci_pipeline_schedules,
        :project_id,
        :pipeline_schedule_id
      ]
    )
  end
end
