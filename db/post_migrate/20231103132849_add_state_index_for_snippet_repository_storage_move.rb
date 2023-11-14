# frozen_string_literal: true

class AddStateIndexForSnippetRepositoryStorageMove < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.6'

  INDEX_NAME = 'index_snippet_repository_storage_moves_on_state'

  def up
    # State 2 = scheduled and 3 = started
    add_concurrent_index :snippet_repository_storage_moves, :state, where: 'state IN (2, 3)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippet_repository_storage_moves, INDEX_NAME
  end
end
