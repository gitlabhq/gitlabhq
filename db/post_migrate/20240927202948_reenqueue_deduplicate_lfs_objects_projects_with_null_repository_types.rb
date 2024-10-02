# frozen_string_literal: true

class ReenqueueDeduplicateLfsObjectsProjectsWithNullRepositoryTypes < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  MIGRATION = 'DeduplicateLfsObjectsProjects'
  TABLE_NAME = :lfs_objects_projects
  DELAY_INTERVAL = 100
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 2_500

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    delete_batched_background_migration(MIGRATION, :lfs_objects_projects, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :lfs_objects_projects,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :lfs_objects_projects, :id, [])
  end
end
