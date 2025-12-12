# frozen_string_literal: true

class AddKnowledgeGraphEnabledNamespacesNamespaceFk < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :knowledge_graph_enabled_namespaces, :namespaces,
      column: :root_namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :knowledge_graph_enabled_namespaces, column: :root_namespace_id
    end
  end
end
