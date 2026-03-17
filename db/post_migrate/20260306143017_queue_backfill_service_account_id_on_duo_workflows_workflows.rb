# frozen_string_literal: true

class QueueBackfillServiceAccountIdOnDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillServiceAccountIdOnDuoWorkflowsWorkflows"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :duo_workflows_workflows,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :duo_workflows_workflows, :id, [])
  end
end
