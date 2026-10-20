# frozen_string_literal: true

class FinalizeCleanupWebHookLogsDailyShardingKeyOrphans < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'CleanupWebHookLogsDailyShardingKeyOrphans'

  def up
    # The cleanup BBM is only queued on self-managed instances
    # (QueueCleanupWebHookLogsDailyShardingKeyOrphans, 19.3, skips .com), so there is nothing to
    # finalize on .com. The guard is required: in the Database Lab (DBLAB) migration-testing
    # environment, a not-found batched migration raises NonExistentMigrationError.
    #
    # This finalizes in 19.6: the BBM was queued in 19.3, the next required stop is 19.5, and
    # last_required_stop is the last stop strictly below the current version, so a 19.3-queued
    # BBM can only be finalized once the instance is past 19.5 (that is, on 19.6+).
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/603303
    return if Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :web_hook_logs_daily,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
