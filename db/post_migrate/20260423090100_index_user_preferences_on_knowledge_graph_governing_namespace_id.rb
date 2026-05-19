# frozen_string_literal: true

class IndexUserPreferencesOnKnowledgeGraphGoverningNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_user_preferences_on_knowledge_graph_governing_namespace_id'

  def up
    add_concurrent_index :user_preferences, :knowledge_graph_governing_namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_preferences, INDEX_NAME
  end
end
