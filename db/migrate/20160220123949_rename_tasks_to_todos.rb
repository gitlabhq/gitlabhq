class RenameTasksToTodos < ActiveRecord::Migration[4.2]
  def change
    rename_table :tasks, :todos
  end
end
