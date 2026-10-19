# frozen_string_literal: true

class AddRepositoryStorageToPKnowledgeGraphCodeIndexingTasks < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_kg_code_indexing_tasks_repository_storage_limit'

  def up
    with_lock_retries do
      add_column :p_knowledge_graph_code_indexing_tasks, :repository_storage, :text, if_not_exists: true
    end

    add_text_limit :p_knowledge_graph_code_indexing_tasks, :repository_storage, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_column :p_knowledge_graph_code_indexing_tasks, :repository_storage, if_exists: true
    end
  end
end
