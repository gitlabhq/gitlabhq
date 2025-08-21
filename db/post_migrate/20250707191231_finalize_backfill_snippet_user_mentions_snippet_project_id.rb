# frozen_string_literal: true

class FinalizeBackfillSnippetUserMentionsSnippetProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSnippetUserMentionsSnippetProjectId',
      table_name: :snippet_user_mentions,
      column_name: :id,
      job_arguments: [:snippet_project_id, :snippets, :project_id, :snippet_id],
      finalize: true
    )
  end

  def down; end
end
