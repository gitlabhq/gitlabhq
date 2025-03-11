# frozen_string_literal: true

class QueueUpdateClosedMergedMrs < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  MIGRATION = "UpdateClosedMergedMrs"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com_except_jh?

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
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :merge_requests, :id, [])
  end
end
