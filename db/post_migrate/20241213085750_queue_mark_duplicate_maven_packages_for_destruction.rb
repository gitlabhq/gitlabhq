# frozen_string_literal: true

class QueueMarkDuplicateMavenPackagesForDestruction < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'MarkDuplicateMavenPackagesForDestruction'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10000
  BATCH_CLASS_NAME = 'LooseIndexScanBatchingStrategy'
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_packages,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: BATCH_CLASS_NAME,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_packages, :project_id, [])
  end
end
