# frozen_string_literal: true

class QueueMarkVirtualRegistriesPkgsMvnCacheEntriesPendingDestruction < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE = :virtual_registries_packages_maven_cache_entries
  MIGRATION = 'MarkVirtualRegistriesPackagesMavenCacheEntriesPendingDestruction'
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE,
      :upstream_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE, :upstream_id, [])
  end
end
