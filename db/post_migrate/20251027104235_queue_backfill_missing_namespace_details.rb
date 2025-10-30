# frozen_string_literal: true

class QueueBackfillMissingNamespaceDetails < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillMissingNamespaceDetails"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    return unless should_run?

    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end

  private

  def should_run?
    # Check if the old migration already exists to avoid re-queueing
    if Gitlab::Database::BackgroundMigration::BatchedMigration.for_configuration(
      :gitlab_main,
      "BackfillNamespaceDetails",
      :namespaces,
      :id,
      [],
      include_compatible: true
    ).exists?
      Gitlab::AppLogger.warn "Batched background migration not enqueued because it already exists: " \
        "job_class_name: BackfillNamespaceDetails,
        table_name: namespaces, column_name: id, " \
        "job_arguments: []"
      false
    end

    true
  end
end
