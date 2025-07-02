# frozen_string_literal: true

class QueueBackfillSentNotificationsAfterPartition < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillSentNotificationsAfterPartition"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 200
  GITLAB_OPTIMIZED_BATCH_SIZE = 30_000
  GITLAB_OPTIMIZED_MAX_BATCH_SIZE = 75_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 500

  # ID based on a manual search of the sent_notifications table. ID for records created approximately around
  # 2024-06-13, so approximately 1 years ago at the time of writing. We plan to preserve only 1 year of records from
  # now on
  DOT_COM_START_ID = 2290000000

  class MigrationPartSentNotification < MigrationRecord
    extend SuppressCompositePrimaryKeyWarning
    include PartitionedTable

    self.table_name = :sent_notifications_7abbf02cb6

    partitioned_by :created_at, strategy: :monthly, retain_for: 1.year
  end

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sent_notifications,
      :id,
      batch_min_value: batch_start_id,
      batch_max_value: batch_end_id,
      **batch_sizes
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sent_notifications, :id, [])
  end

  private

  def batch_sizes
    if Gitlab.com_except_jh?
      {
        batch_size: GITLAB_OPTIMIZED_BATCH_SIZE,
        sub_batch_size: GITLAB_OPTIMIZED_SUB_BATCH_SIZE,
        max_batch_size: GITLAB_OPTIMIZED_MAX_BATCH_SIZE
      }
    else
      {
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      }
    end
  end

  def batch_start_id
    return DOT_COM_START_ID if Gitlab.com_except_jh?

    1
  end

  def batch_end_id
    minimum_partitioned = MigrationPartSentNotification.minimum(:id)

    minimum_partitioned if minimum_partitioned && minimum_partitioned >= batch_start_id
  end
end
