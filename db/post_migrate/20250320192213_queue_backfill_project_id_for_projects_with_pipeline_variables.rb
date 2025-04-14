# frozen_string_literal: true

class QueueBackfillProjectIdForProjectsWithPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillProjectIdForProjectsWithPipelineVariables"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :p_ci_pipeline_variables,
      :project_id,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :p_ci_pipeline_variables, :project_id, [])
  end
end
