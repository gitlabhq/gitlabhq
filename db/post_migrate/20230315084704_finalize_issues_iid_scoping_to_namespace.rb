# frozen_string_literal: true

class FinalizeIssuesIidScopingToNamespace < Gitlab::Database::Migration[2.1]
  MIGRATION = 'IssuesInternalIdScopeUpdater'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :internal_ids,
      column_name: :id,
      job_arguments: [],
      finalize: true)
  end

  def down; end
end
