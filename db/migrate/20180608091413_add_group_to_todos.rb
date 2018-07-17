class AddGroupToTodos < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :todos, :group_id, :integer
    add_concurrent_foreign_key :todos, :namespaces, column: :group_id, on_delete: :cascade
    add_concurrent_index :todos, :group_id

    change_column_null :todos, :project_id, true
  end

  def down
    return unless group_id_exists?

    remove_foreign_key :todos, column: :group_id
    remove_index :todos, :group_id if index_exists?(:todos, :group_id)
    remove_column :todos, :group_id

    execute "DELETE FROM todos WHERE project_id IS NULL"
    change_column_null :todos, :project_id, false
  end

  private

  def group_id_exists?
    column_exists?(:todos, :group_id)
  end
end
