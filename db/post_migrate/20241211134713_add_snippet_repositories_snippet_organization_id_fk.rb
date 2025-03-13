# frozen_string_literal: true

class AddSnippetRepositoriesSnippetOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :snippet_repositories, :organizations, column: :snippet_organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_repositories, column: :snippet_organization_id
    end
  end
end
