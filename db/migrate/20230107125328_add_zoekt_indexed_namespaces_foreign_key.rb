# frozen_string_literal: true

class AddZoektIndexedNamespacesForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :zoekt_indexed_namespaces, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_indexed_namespaces, column: :namespace_id
    end
  end
end
