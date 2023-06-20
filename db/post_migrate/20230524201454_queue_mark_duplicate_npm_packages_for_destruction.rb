# frozen_string_literal: true

class QueueMarkDuplicateNpmPackagesForDestruction < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MarkDuplicateNpmPackagesForDestruction'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  BATCH_CLASS_NAME = 'LooseIndexScanBatchingStrategy'
  SUB_BATCH_SIZE = 500

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

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
