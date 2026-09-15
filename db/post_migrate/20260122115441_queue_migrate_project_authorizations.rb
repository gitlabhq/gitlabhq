# frozen_string_literal: true

class QueueMigrateProjectAuthorizations < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = 'project_authorizations'
  MIGRATION = "MigrateProjectAuthorizations"

  def up
    # no-op because rows synced by the trigger on `project_authorizations`
    # could get lost from `project_authorizations_for_migration`, so the
    # batched background migration was requeued by
    # RequeueMigrateProjectAuthorizations.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/526000
  end

  def down
    # no-op because the batched background migration was requeued by
    # RequeueMigrateProjectAuthorizations.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/526000
  end
end
