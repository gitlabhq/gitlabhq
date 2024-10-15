# frozen_string_literal: true

class QueueBackfillIncidentManagementTimelineEventTagLinksProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillIncidentManagementTimelineEventTagLinksProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :incident_management_timeline_event_tag_links,
      :id,
      :project_id,
      :incident_management_timeline_event_tags,
      :project_id,
      :timeline_event_tag_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :incident_management_timeline_event_tag_links,
      :id,
      [
        :project_id,
        :incident_management_timeline_event_tags,
        :project_id,
        :timeline_event_tag_id
      ]
    )
  end
end
