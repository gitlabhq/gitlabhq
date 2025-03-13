# frozen_string_literal: true

class AddSnippetStatisticsSnippetOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :snippet_statistics, :organizations, column: :snippet_organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :snippet_statistics, column: :snippet_organization_id
    end
  end
end
