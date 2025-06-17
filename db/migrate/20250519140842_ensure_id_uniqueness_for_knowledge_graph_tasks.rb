# frozen_string_literal: true

class EnsureIdUniquenessForKnowledgeGraphTasks < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '18.1'

  TABLE_NAME = :p_knowledge_graph_tasks
  SEQ_NAME = :p_knowledge_graph_tasks_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
