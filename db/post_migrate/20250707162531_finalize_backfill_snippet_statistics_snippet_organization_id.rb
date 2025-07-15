# frozen_string_literal: true

class FinalizeBackfillSnippetStatisticsSnippetOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSnippetStatisticsSnippetOrganizationId',
      table_name: :snippet_statistics,
      column_name: :snippet_id,
      job_arguments: [:snippet_organization_id, :snippets, :organization_id, :snippet_id],
      finalize: true
    )
  end

  def down; end
end
