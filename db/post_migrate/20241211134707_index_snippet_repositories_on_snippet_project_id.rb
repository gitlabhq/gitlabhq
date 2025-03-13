# frozen_string_literal: true

class IndexSnippetRepositoriesOnSnippetProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_snippet_repositories_on_snippet_project_id'

  def up
    add_concurrent_index :snippet_repositories, :snippet_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_repositories, INDEX_NAME
  end
end
