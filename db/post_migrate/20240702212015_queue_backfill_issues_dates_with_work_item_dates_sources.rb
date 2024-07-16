# frozen_string_literal: true

class QueueBackfillIssuesDatesWithWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillIssuesDatesWithWorkItemDatesSources"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :work_item_dates_sources,
      :issue_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :work_item_dates_sources, :issue_id, [])
  end
end
