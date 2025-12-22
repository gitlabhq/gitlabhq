# frozen_string_literal: true

class RemoveColumnZoektNodeKnowledgeGraphSchemaVersion < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    remove_column :zoekt_nodes, :knowledge_graph_schema_version
  end

  def down
    add_column :zoekt_nodes, :knowledge_graph_schema_version, :smallint, default: 0, null: false
  end
end
