# frozen_string_literal: true

class AddProjectWikiRepositoryIdToProjectWikiRepositoryStates < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_project_wiki_repository_states_project_wiki_repository_id'

  def up
    with_lock_retries do
      unless column_exists?(:project_wiki_repository_states, :project_wiki_repository_id)
        add_column :project_wiki_repository_states, :project_wiki_repository_id, :bigint
      end
    end

    add_concurrent_index :project_wiki_repository_states,
      :project_wiki_repository_id,
      name: INDEX_NAME

    add_concurrent_foreign_key :project_wiki_repository_states,
      :project_wiki_repositories,
      column: :project_wiki_repository_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      if column_exists?(:project_wiki_repository_states, :project_wiki_repository_id)
        remove_column :project_wiki_repository_states, :project_wiki_repository_id
      end
    end

    remove_foreign_key_if_exists :project_wiki_repository_states, column: :project_wiki_repository_id
    remove_concurrent_index_by_name :project_wiki_repository_states, name: INDEX_NAME
  end
end
