# frozen_string_literal: true

class QueueBackfillPackagesComposerPackagesTable < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillPackagesComposerPackagesTable'
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_packages,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_packages, :id, [])
  end
end
