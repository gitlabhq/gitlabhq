# frozen_string_literal: true

class QueueSyncUnlinkedSecurityPolicyProjectLinks < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "SyncUnlinkedSecurityPolicyProjectLinks"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :security_policies,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_policies, :id, [])
  end
end
