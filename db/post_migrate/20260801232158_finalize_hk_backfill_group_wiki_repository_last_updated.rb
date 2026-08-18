# frozen_string_literal: true

class FinalizeHkBackfillGroupWikiRepositoryLastUpdated < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillGroupWikiRepositoryLastUpdated',
      table_name: :group_wiki_repositories,
      column_name: :group_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
