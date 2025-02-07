# frozen_string_literal: true

class AddSnippetOrganizationIdToSnippetRepositoryStorageMoves < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :snippet_repository_storage_moves, :snippet_organization_id, :bigint
  end
end
