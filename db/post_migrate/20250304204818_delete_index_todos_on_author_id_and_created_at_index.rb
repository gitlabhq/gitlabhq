# frozen_string_literal: true

class DeleteIndexTodosOnAuthorIdAndCreatedAtIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  TABLE_NAME = :todos
  INDEX_NAME = 'index_todos_on_author_id'

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :author_id, name: INDEX_NAME
  end
end
