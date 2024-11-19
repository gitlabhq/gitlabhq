# frozen_string_literal: true

class QueueBackfillCiTriggerRequestsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiTriggerRequestsProjectId"
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_trigger_requests,
      :id,
      :project_id,
      :ci_triggers,
      :project_id,
      :trigger_id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :ci_trigger_requests,
      :id,
      [
        :project_id,
        :ci_triggers,
        :project_id,
        :trigger_id
      ]
    )
  end
end
