# frozen_string_literal: true

class RequeueBackfillPushEventPayloadsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillPushEventPayloadsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(
      MIGRATION,
      :push_event_payloads,
      :event_id,
      [
        :project_id,
        :events,
        :project_id,
        :event_id
      ]
    )

    queue_batched_background_migration(
      MIGRATION,
      :push_event_payloads,
      :event_id,
      :project_id,
      :events,
      :project_id,
      :event_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :push_event_payloads,
      :event_id,
      [
        :project_id,
        :events,
        :project_id,
        :event_id
      ]
    )
  end
end
