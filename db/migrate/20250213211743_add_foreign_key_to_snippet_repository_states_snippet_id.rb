# frozen_string_literal: true

class AddForeignKeyToSnippetRepositoryStatesSnippetId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  def up
    add_concurrent_foreign_key :snippet_repository_states,
      :snippet_repositories,
      column: :snippet_repository_id,
      target_column: :snippet_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_repository_states, column: :snippet_repository_id
    end
  end
end
