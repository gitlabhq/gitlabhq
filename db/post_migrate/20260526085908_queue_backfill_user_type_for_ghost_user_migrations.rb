# frozen_string_literal: true

class QueueBackfillUserTypeForGhostUserMigrations < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  MIGRATION = "BackfillUserTypeForGhostUserMigrations"
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ghost_user_migrations,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ghost_user_migrations, :id, [])
  end
end
