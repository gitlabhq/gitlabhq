# frozen_string_literal: true

class IndexWikiRepositoryStatesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_wiki_repository_states_on_project_id'

  def up
    add_concurrent_index :wiki_repository_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :wiki_repository_states, INDEX_NAME
  end
end
