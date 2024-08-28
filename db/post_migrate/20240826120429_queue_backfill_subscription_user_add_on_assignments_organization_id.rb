# frozen_string_literal: true

class QueueBackfillSubscriptionUserAddOnAssignmentsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillSubscriptionUserAddOnAssignmentsOrganizationId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :subscription_user_add_on_assignments,
      :id,
      :organization_id,
      :subscription_add_on_purchases,
      :organization_id,
      :add_on_purchase_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :subscription_user_add_on_assignments,
      :id,
      [
        :organization_id,
        :subscription_add_on_purchases,
        :organization_id,
        :add_on_purchase_id
      ]
    )
  end
end
