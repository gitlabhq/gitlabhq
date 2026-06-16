# frozen_string_literal: true

class QueueDeleteOrphanedProjectRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "DeleteOrphanedProjectRepositories"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_repositories,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_repositories, :id, [])
  end
end
