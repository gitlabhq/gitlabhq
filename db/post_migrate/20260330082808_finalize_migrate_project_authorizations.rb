# frozen_string_literal: true

class FinalizeMigrateProjectAuthorizations < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op because the batched background migration was requeued by
    # RequeueMigrateProjectAuthorizations.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/526000
  end

  def down
    # no-op
  end
end
