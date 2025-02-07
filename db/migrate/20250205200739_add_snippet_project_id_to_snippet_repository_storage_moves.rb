# frozen_string_literal: true

class AddSnippetProjectIdToSnippetRepositoryStorageMoves < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :snippet_repository_storage_moves, :snippet_project_id, :bigint
  end
end
