# frozen_string_literal: true

class RequeueDeleteOrphanedGroups < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "DeleteOrphanedGroups"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  BATCH_START_ID = 71486000
  BATCH_END_ID = 71487000

  def up
    return unless Gitlab.com_except_jh? && !Gitlab.staging?

    # Clear previous background migration execution from QueueRequeueDeleteOrphanedGroups
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: BATCH_START_ID,
      batch_max_value: BATCH_END_ID
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
