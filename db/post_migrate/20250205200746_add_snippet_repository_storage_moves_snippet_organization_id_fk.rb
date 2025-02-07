# frozen_string_literal: true

class AddSnippetRepositoryStorageMovesSnippetOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :snippet_repository_storage_moves, :organizations, column: :snippet_organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_repository_storage_moves, column: :snippet_organization_id
    end
  end
end
