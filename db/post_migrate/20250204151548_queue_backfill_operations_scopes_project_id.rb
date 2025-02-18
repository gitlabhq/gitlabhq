# frozen_string_literal: true

class QueueBackfillOperationsScopesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillOperationsScopesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :operations_scopes,
      :id,
      :project_id,
      :operations_strategies,
      :project_id,
      :strategy_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :operations_scopes,
      :id,
      [
        :project_id,
        :operations_strategies,
        :project_id,
        :strategy_id
      ]
    )
  end
end
