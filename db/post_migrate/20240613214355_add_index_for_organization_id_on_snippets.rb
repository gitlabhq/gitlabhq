# frozen_string_literal: true

class AddIndexForOrganizationIdOnSnippets < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  TABLE_NAME = :snippets
  INDEX_NAME = 'index_snippets_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
