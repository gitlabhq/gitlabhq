# frozen_string_literal: true

class QueueBackfillPCiPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE = :ci_trigger_requests
  PRIMARY_KEY = :id
  MIGRATION = "BackfillPCiPipelinesTriggerId"
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION, TABLE, PRIMARY_KEY, job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION, TABLE, PRIMARY_KEY, []
    )
  end
end
