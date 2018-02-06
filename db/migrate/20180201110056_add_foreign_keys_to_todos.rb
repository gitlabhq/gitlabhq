class AddForeignKeysToTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Todo < ActiveRecord::Base
    self.table_name = 'todos'
    include EachBatch
  end

  BATCH_SIZE = 1000

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Todo.where('NOT EXISTS ( SELECT true FROM users WHERE id=todos.user_id )').each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    Todo.where('NOT EXISTS ( SELECT true FROM users WHERE id=todos.author_id )').each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    Todo.where('note_id IS NOT NULL AND NOT EXISTS ( SELECT true FROM notes WHERE id=todos.note_id )').each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    add_concurrent_foreign_key :todos, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :todos, :users, column: :author_id, on_delete: :cascade
    add_concurrent_foreign_key :todos, :notes, column: :note_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :todos, :users
    remove_foreign_key :todos, column: :author_id
    remove_foreign_key :todos, :notes
  end
end
