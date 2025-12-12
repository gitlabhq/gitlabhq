# frozen_string_literal: true

class CreateKnowledgeGraphEnabledNamespaces < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    create_table :knowledge_graph_enabled_namespaces do |t|
      t.bigint :root_namespace_id, null: false, index: { unique: true }
      t.timestamps_with_timezone null: false
    end
  end
end
