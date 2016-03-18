class AddCommitIdToTodos < ActiveRecord::Migration
  def change
    add_column :todos, :commit_id, :string
    add_index :todos, :commit_id
  end
end
