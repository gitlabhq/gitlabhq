# frozen_string_literal: true

class RequeueDeleteNullProjectIdPushRules < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "DeleteNullProjectIdPushRules"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    # Only requeue on self-managed. The original run queued by
    # QueueDeleteNullProjectIdPushRules (19.2) executes before the NOT NULL
    # constraint on push_rules.project_id (20260715040848) exists, leaving a
    # window where NULL project_id rows could still appear. Requeuing after
    # the constraint guarantees the cleanup runs when no new NULL rows can be
    # created, so the deferred self-managed finalize and validation
    # (https://gitlab.com/gitlab-org/gitlab/-/work_items/607954 and
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/607955) cannot fail.
    #
    # On GitLab.com the migration was already finalized by
    # FinalizeHkDeleteNullProjectIdPushRules (20260713080858), so this is a
    # no-op there.
    return if Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :push_rules, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :push_rules,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return if Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :push_rules, :id, [])
  end
end
