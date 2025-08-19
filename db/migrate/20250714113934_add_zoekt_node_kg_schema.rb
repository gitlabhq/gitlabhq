# frozen_string_literal: true

class AddZoektNodeKgSchema < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :zoekt_nodes, :knowledge_graph_schema_version, :smallint, null: false, default: 0
  end
end
