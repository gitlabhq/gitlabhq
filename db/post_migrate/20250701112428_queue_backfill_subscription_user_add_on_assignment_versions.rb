# frozen_string_literal: true

class QueueBackfillSubscriptionUserAddOnAssignmentVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.3'

  MIGRATION = "BackfillSubscriptionUserAddOnAssignmentVersions"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE     = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :subscription_user_add_on_assignments,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      'BackfillSubscriptionUserAddOnAssignmentVersions',
      :subscription_user_add_on_assignments,
      :id,
      []
    )
  end
end
