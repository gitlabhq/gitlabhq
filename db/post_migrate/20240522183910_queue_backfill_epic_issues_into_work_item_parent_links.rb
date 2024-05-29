# frozen_string_literal: true

class QueueBackfillEpicIssuesIntoWorkItemParentLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillEpicIssuesIntoWorkItemParentLinks"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100
  # not passing any group id, means we'd backfill everything. We still have the option to pass in a group id if we
  # need to reschedule the backfilling for a single group
  GROUP_ID = nil

  def up
    queue_batched_background_migration(
      MIGRATION,
      :epic_issues,
      :id,
      GROUP_ID,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epic_issues, :id, [GROUP_ID])
  end
end
