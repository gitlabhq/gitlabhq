# frozen_string_literal: true

class AddNamespaceIdIndexesForeignKeyToProtectedBranches < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_protected_branches_namespace_id'

  def up
    add_concurrent_index :protected_branches, :namespace_id, name: INDEX_NAME, where: 'namespace_id IS NOT NULL'
    add_concurrent_foreign_key :protected_branches, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :protected_branches, column: :namespace_id
    end
    remove_concurrent_index :protected_branches, :namespace_id, name: INDEX_NAME
  end
end
