# frozen_string_literal: true

class QueueBackfillStatusPagePublishedIncidentsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillStatusPagePublishedIncidentsNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :status_page_published_incidents,
      :id,
      :namespace_id,
      :issues,
      :namespace_id,
      :issue_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :status_page_published_incidents,
      :id,
      [
        :namespace_id,
        :issues,
        :namespace_id,
        :issue_id
      ]
    )
  end
end
