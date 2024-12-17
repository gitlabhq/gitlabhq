# frozen_string_literal: true

class IndexGroupWikiRepositoryStatesOnGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_group_wiki_repository_states_on_group_id'

  def up
    add_concurrent_index :group_wiki_repository_states, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :group_wiki_repository_states, INDEX_NAME
  end
end
