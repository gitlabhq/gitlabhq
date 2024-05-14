# frozen_string_literal: true

class FinalizeUpdateDelayedProjectRemovalToNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'UpdateDelayedProjectRemovalToNullForUserNamespaces'

  def up
    # We are deleting the migration because there could be instances where the migration to remove the
    # column delayed_project_removal was already executed before this migration.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/451760#note_1835290333 for details.
    delete_batched_background_migration(MIGRATION, :namespace_settings, :namespace_id, [])
  end

  def down
    # noop
  end
end
