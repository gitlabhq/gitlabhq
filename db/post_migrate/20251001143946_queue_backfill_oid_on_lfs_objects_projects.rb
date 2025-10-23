# frozen_string_literal: true

class QueueBackfillOidOnLfsObjectsProjects < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillOidOnLfsObjectsProjects"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :lfs_objects_projects,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :lfs_objects_projects, :id, [])
  end
end
