# frozen_string_literal: true

class QueueFixSyncedEpicWorkItemParentLinks < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "FixSyncedEpicWorkItemParentLinks"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    # We never released a version with this bug on self managed instances. We therefore can run the
    # migration only on .com.
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    queue_batched_background_migration(
      MIGRATION,
      :epics,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    delete_batched_background_migration(MIGRATION, :epics, :id, [])
  end
end
