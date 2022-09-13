# frozen_string_literal: true

class AddIndexToTodosPendingQuery < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_todos_user_project_target_and_state'
  COLUMNS = %i[user_id project_id target_type target_id id].freeze

  def up
    add_concurrent_index :todos, COLUMNS, name: INDEX_NAME, where: "state = 'pending'"
  end

  def down
    remove_concurrent_index_by_name :todos, INDEX_NAME
  end
end
