class ChangeAuthorIdToNotNullInTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Todo < ActiveRecord::Base
    self.table_name = 'todos'
    include EachBatch
  end

  BATCH_SIZE = 1000

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Todo.where(author_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end

    change_column_null :todos, :author_id, false
  end

  def down
    change_column_null :todos, :author_id, true
  end
end
