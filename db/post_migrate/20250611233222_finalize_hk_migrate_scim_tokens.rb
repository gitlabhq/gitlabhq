# frozen_string_literal: true

class FinalizeHkMigrateScimTokens < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'MigrateScimTokens',
      table_name: :scim_oauth_access_tokens,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
