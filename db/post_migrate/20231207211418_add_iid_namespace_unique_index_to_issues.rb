# frozen_string_literal: true

class AddIidNamespaceUniqueIndexToIssues < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_issues_on_namespace_id_iid_unique'

  disable_ddl_transaction!

  milestone '16.8'

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index :issues, [:namespace_id, :iid], name: INDEX_NAME, unique: true
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
