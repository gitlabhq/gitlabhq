# frozen_string_literal: true

class NullifyCreatorIdOfOrphanedProjects < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 500
  MAX_BATCH_SIZE = 5000
  MIGRATION = 'NullifyCreatorIdColumnOfOrphanedProjects'
  INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
