# rubocop:disable all
class AddCommitIdToTodos < ActiveRecord::Migration[4.2]
  def change
    add_column :todos, :commit_id, :string
    add_index :todos, :commit_id
  end
end
