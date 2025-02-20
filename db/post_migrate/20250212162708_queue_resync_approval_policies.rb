# frozen_string_literal: true

class QueueResyncApprovalPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "ResyncApprovalPolicies"
  DELAY_INTERVAL = 10.minutes
  BATCH_SIZE = 10
  SUB_BATCH_SIZE = 10

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
