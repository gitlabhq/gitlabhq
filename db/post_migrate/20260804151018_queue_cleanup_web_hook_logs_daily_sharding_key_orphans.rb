# frozen_string_literal: true

class QueueCleanupWebHookLogsDailyShardingKeyOrphans < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "CleanupWebHookLogsDailyShardingKeyOrphans"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  def up
    # NOTE: .com has no orphan rows (the sharding key was validated long ago) and
    #       web_hook_logs_daily is one of its largest tables, so scanning it in the background
    #       would be pure waste. Only self-managed instances need the cleanup; there the table
    #       is bounded to ~7 daily partitions. A background migration is used instead of a
    #       synchronous delete so it is not bound by the deploy migration window on a large
    #       self-managed table. The constraint is validated in a later release, gated on this
    #       migration being finished.
    #       See https://gitlab.com/gitlab-org/gitlab/-/work_items/603303
    return if Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :web_hook_logs_daily,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return if Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :web_hook_logs_daily, :id, [])
  end
end
