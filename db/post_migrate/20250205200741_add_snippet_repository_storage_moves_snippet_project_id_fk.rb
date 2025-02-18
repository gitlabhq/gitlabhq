# frozen_string_literal: true

class AddSnippetRepositoryStorageMovesSnippetProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :snippet_repository_storage_moves, :projects, column: :snippet_project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_repository_storage_moves, column: :snippet_project_id
    end
  end
end
