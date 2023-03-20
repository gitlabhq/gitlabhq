# frozen_string_literal: true

class QueueBackfillPreparedAtData < Gitlab::Database::Migration[2.1]
  MIGRATION = 'BackfillPreparedAtMergeRequests'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :merge_requests,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: 5000,
      sub_batch_size: 250
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :merge_requests, :id, [])
  end
end
