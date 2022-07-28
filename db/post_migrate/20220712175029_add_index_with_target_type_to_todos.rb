# frozen_string_literal: true

class AddIndexWithTargetTypeToTodos < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_FOR_PROJECTS_NAME = 'index_requirements_project_id_user_id_id_and_target_type'
  INDEX_FOR_TARGET_TYPE_NAME = 'index_requirements_user_id_and_target_type'

  def up
    add_concurrent_index :todos, [:project_id, :user_id, :id, :target_type], name: INDEX_FOR_PROJECTS_NAME
    add_concurrent_index :todos, [:user_id, :target_type], name: INDEX_FOR_TARGET_TYPE_NAME
  end

  def down
    remove_concurrent_index_by_name :todos, INDEX_FOR_PROJECTS_NAME
    remove_concurrent_index_by_name :todos, INDEX_FOR_TARGET_TYPE_NAME
  end
end
