# frozen_string_literal: true

class RequeueBackfillFreeSharedRunnersMinutesLimit < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillFreeSharedRunnersMinutesLimit"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 100

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.com_except_jh?

    # Clear previous background migration execution from QueueBackfillFreeSharedRunnersMinutesLimit
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.dev_or_test_env? || Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
