# frozen_string_literal: true

class QueueBackfillPCiPipelineVariablesFromCiTriggerRequests < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillPCiPipelineVariablesFromCiTriggerRequests"
  TABLE = :ci_trigger_requests
  COLUMN = :id
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE,
      COLUMN,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE, COLUMN, [])
  end
end
