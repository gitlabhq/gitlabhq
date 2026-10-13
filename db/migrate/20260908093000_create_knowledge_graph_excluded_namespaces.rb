# frozen_string_literal: true

class CreateKnowledgeGraphExcludedNamespaces < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :knowledge_graph_excluded_namespaces, id: false do |t|
      t.bigint :root_namespace_id, primary_key: true, default: nil
      t.timestamps_with_timezone null: false

      t.foreign_key :namespaces, column: :root_namespace_id, on_delete: :cascade
    end
  end
end
