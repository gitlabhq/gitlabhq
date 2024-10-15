# frozen_string_literal: true

class FinalizeNullifyOrganizationIdForSnippets < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'NullifyOrganizationIdForSnippets',
      table_name: 'snippets',
      column_name: 'id',
      job_arguments: [],
      finalize: true
    )
  end
end
