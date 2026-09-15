# frozen_string_literal: true

class RequeueMigrateProjectAuthorizations < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = :project_authorizations
  MIGRATION = "MigrateProjectAuthorizations"

  def up
    # Clear the previous, already finalized run from
    # QueueMigrateProjectAuthorizations
    delete_batched_background_migration(MIGRATION, TABLE_NAME, :user_id, [])

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      :user_id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, :user_id, [])
  end
end
