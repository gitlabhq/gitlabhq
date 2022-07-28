# frozen_string_literal: true

class RemoveDeprecatedIndexesFromTodos < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  PROJECTS_INDEX = 'index_todos_on_project_id_and_user_id_and_id'
  USERS_INDEX = 'index_todos_on_user_id'

  # These indexes are deprecated in favor of two new ones
  # added in a previous migration:
  #
  # * index_requirements_project_id_user_id_target_type_and_id
  # * index_requirements_user_id_and_target_type
  def up
    remove_concurrent_index_by_name :todos, PROJECTS_INDEX
    remove_concurrent_index_by_name :todos, USERS_INDEX
  end

  def down
    add_concurrent_index :todos, [:project_id, :user_id, :id], name: PROJECTS_INDEX
    add_concurrent_index :todos, :user_id, name: USERS_INDEX
  end
end
