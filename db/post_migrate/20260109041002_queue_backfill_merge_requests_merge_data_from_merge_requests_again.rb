# frozen_string_literal: true

class QueueBackfillMergeRequestsMergeDataFromMergeRequestsAgain < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillMergeRequestsMergeDataFromMergeRequests"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :merge_requests, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :merge_requests,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :merge_requests, :id, [])
  end
end
