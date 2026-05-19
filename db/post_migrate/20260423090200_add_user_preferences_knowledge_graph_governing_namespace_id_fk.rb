# frozen_string_literal: true

class AddUserPreferencesKnowledgeGraphGoverningNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_preferences,
      :namespaces,
      column: :knowledge_graph_governing_namespace_id,
      on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :user_preferences, column: :knowledge_graph_governing_namespace_id
  end
end
