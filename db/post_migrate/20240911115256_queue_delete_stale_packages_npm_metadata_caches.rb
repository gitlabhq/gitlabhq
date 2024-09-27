# frozen_string_literal: true

class QueueDeleteStalePackagesNpmMetadataCaches < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'DeleteStalePackagesNpmMetadataCaches'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_npm_metadata_caches,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_npm_metadata_caches, :id, [])
  end
end
