# frozen_string_literal: true

class QueueReEnqueueDeleteOrphanedGroups < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "DeleteOrphanedGroups"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

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
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
