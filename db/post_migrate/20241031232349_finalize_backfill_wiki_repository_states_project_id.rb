# frozen_string_literal: true

class FinalizeBackfillWikiRepositoryStatesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWikiRepositoryStatesProjectId',
      table_name: :wiki_repository_states,
      column_name: :id,
      job_arguments: [:project_id, :project_wiki_repositories, :project_id, :project_wiki_repository_id],
      finalize: true
    )
  end

  def down; end
end
