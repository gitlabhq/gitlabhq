# frozen_string_literal: true

class CreatePKnowledgeGraphCodeIndexingTasks < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  OPTIONS = {
    primary_key: [:id, :created_at],
    options: 'PARTITION BY RANGE (created_at)',
    if_not_exists: true
  }

  def up
    create_table :p_knowledge_graph_code_indexing_tasks, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :project_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.text :ref, null: false, limit: 255
      t.text :commit_sha, null: false, limit: 40
      t.text :traversal_path, null: false, limit: 1024
    end
  end

  def down
    drop_table :p_knowledge_graph_code_indexing_tasks
  end
end
