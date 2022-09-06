# frozen_string_literal: true

class AddAsyncIndexToTodosToCoverPendingQuery < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_todos_user_project_target_and_state'
  COLUMNS = %i[user_id project_id target_type target_id id].freeze

  def up
    prepare_async_index :todos, COLUMNS, name: INDEX_NAME, where: "state = 'pending'"
  end

  def down
    unprepare_async_index :todos, COLUMNS, name: INDEX_NAME, where: "state='pending'"
  end
end
