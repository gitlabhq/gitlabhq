# frozen_string_literal: true

class QueueMarkPackagesHelmMetadataCachesPendingDestruction < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "MarkPackagesHelmMetadataCachesPendingDestruction"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_helm_metadata_caches,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_helm_metadata_caches, :id, [])
  end
end
