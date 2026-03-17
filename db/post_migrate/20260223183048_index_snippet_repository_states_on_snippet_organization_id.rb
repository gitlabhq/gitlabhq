# frozen_string_literal: true

class IndexSnippetRepositoryStatesOnSnippetOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_snippet_repository_states_on_snippet_organization_id'

  def up
    add_concurrent_index :snippet_repository_states, :snippet_organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_repository_states, INDEX_NAME
  end
end
