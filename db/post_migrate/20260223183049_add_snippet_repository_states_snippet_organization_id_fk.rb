# frozen_string_literal: true

class AddSnippetRepositoryStatesSnippetOrganizationIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :snippet_repository_states, :organizations, column: :snippet_organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_repository_states, column: :snippet_organization_id
    end
  end
end
