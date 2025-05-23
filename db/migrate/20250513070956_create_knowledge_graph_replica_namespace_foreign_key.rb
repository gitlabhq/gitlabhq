# frozen_string_literal: true

class CreateKnowledgeGraphReplicaNamespaceForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.1'

  def up
    track_record_deletions_override_table_name(:p_knowledge_graph_enabled_namespaces)
  end

  def down
    untrack_record_deletions(:p_knowledge_graph_enabled_namespaces)
  end
end
