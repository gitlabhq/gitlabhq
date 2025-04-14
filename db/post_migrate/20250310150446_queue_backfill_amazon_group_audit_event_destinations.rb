# frozen_string_literal: true

class QueueBackfillAmazonGroupAuditEventDestinations < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillAmazonGroupAuditEventDestinations"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :audit_events_amazon_s3_configurations,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :audit_events_amazon_s3_configurations, :id, [])
  end
end
