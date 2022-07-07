# frozen_string_literal: true

class AddIssuesNamespaceIdFkAndIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  INDEX_NAME = 'index_issues_on_namespace_id'

  def up
    add_concurrent_index :issues, :namespace_id, name: INDEX_NAME
    add_concurrent_foreign_key :issues, :namespaces,
      column: :namespace_id,
      on_delete: :nullify,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :issues, column: :namespace_id
    end

    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
