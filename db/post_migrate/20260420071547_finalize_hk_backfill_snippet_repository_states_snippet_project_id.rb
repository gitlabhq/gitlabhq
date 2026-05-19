# frozen_string_literal: true

class FinalizeHkBackfillSnippetRepositoryStatesSnippetProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSnippetRepositoryStatesSnippetProjectId',
      table_name: :snippet_repository_states,
      column_name: :id,
      job_arguments: [:snippet_project_id, :snippet_repositories, :snippet_project_id, :snippet_repository_id],
      finalize: true
    )
  end

  def down; end
end
