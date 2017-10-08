# rubocop:disable all
class AddProjectPathIndex < ActiveRecord::Migration[4.2]
  def up
    add_index :projects, :path
  end

  def down
    remove_index :projects, :path
  end
end
