# rubocop:disable all
class RenameTasksToTodos < ActiveRecord::Migration
  def change
    rename_table :tasks, :todos
  end
end
