# frozen_string_literal: true

class FinalizeProjectBotUserDetailsBotNamespaceMigration < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: "ProjectBotUserDetailsBotNamespaceMigration",
      table_name: :users,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
