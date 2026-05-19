# frozen_string_literal: true

class AddKnowledgeGraphGoverningNamespaceIdToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :user_preferences, :knowledge_graph_governing_namespace_id, :bigint
  end
end
