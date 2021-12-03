# frozen_string_literal: true

class AddIndexTodosProjectIdUserId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_todos_on_project_id_and_user_id_and_id'

  def up
    add_concurrent_index :todos, [:project_id, :user_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :todos, INDEX_NAME
  end
end
