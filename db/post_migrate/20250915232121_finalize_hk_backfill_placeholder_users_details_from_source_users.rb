# frozen_string_literal: true

class FinalizeHkBackfillPlaceholderUsersDetailsFromSourceUsers < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPlaceholderUsersDetailsFromSourceUsers',
      table_name: :import_source_users,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
