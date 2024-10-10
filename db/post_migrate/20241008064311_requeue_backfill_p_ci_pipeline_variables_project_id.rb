# frozen_string_literal: true

class RequeueBackfillPCiPipelineVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPCiPipelineVariablesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 75_000
  SUB_BATCH_SIZE = 250
  TABLE_NAME = :p_ci_pipeline_variables
  BATCH_COLUMN = :id
  JOB_ARGS = %i[project_id p_ci_pipelines project_id pipeline_id partition_id]

  def up
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      *JOB_ARGS,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, JOB_ARGS)
  end
end
