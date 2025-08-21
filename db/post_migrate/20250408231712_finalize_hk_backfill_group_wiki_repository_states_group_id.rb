# frozen_string_literal: true

class FinalizeHkBackfillGroupWikiRepositoryStatesGroupId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillGroupWikiRepositoryStatesGroupId',
      table_name: :group_wiki_repository_states,
      column_name: :id,
      job_arguments: [:group_id, :group_wiki_repositories, :group_id, :group_wiki_repository_id],
      finalize: true
    )
  end

  def down; end
end
