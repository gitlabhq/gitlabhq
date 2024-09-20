# frozen_string_literal: true

class QueueBackfillAlertManagementAlertUserMentionsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillAlertManagementAlertUserMentionsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :alert_management_alert_user_mentions,
      :id,
      :project_id,
      :alert_management_alerts,
      :project_id,
      :alert_management_alert_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :alert_management_alert_user_mentions,
      :id,
      [
        :project_id,
        :alert_management_alerts,
        :project_id,
        :alert_management_alert_id
      ]
    )
  end
end
