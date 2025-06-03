# frozen_string_literal: true

class AddKnowledgeGraphTask < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  OPTIONS = {
    primary_key: [:id, :partition_id],
    options: 'PARTITION BY LIST (partition_id)',
    if_not_exists: true
  }
  FAILED_STATE_ENUM = 255
  CONSTRAINT_QUERY = <<~SQL
    (retries_left > 0) OR (retries_left = 0 AND state = #{FAILED_STATE_ENUM})
  SQL

  def change
    create_table :p_knowledge_graph_tasks, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false, default: 1
      t.bigint :zoekt_node_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :knowledge_graph_replica_id, null: false
      t.datetime_with_timezone :perform_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :state, null: false, default: 0, limit: 2
      t.integer :task_type, null: false, limit: 2
      t.integer :retries_left, null: false, limit: 2
      t.index :state, name: 'index_p_knowledge_graph_tasks_on_state', using: :btree
      t.index :knowledge_graph_replica_id
      t.index [:zoekt_node_id, :state, :perform_at],
        name: 'index_p_knowledge_graph_tasks_on_node_state_and_perform_at', using: :btree
      t.check_constraint CONSTRAINT_QUERY, name: 'c_p_knowledge_graph_tasks_on_retries_left'
    end
  end
end
