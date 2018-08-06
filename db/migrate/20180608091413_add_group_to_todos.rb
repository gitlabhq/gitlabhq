class AddGroupToTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Todo < ActiveRecord::Base
    self.table_name = 'todos'

    include ::EachBatch
  end

  def up
    add_column(:todos, :group_id, :integer) unless group_id_exists?
    add_concurrent_foreign_key :todos, :namespaces, column: :group_id, on_delete: :cascade
    add_concurrent_index :todos, :group_id

    change_column_null :todos, :project_id, true
  end

  def down
    remove_foreign_key_without_error(:todos, column: :group_id)
    remove_concurrent_index(:todos, :group_id)
    remove_column(:todos, :group_id) if group_id_exists?

    Todo.where(project_id: nil).each_batch { |batch| batch.delete_all }
    change_column_null :todos, :project_id, false
  end

  private

  def group_id_exists?
    column_exists?(:todos, :group_id)
  end
end
