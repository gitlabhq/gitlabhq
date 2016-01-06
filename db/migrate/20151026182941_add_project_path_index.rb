class AddProjectPathIndex < ActiveRecord::Migration
  def up
    add_index :projects, :path
  end

  def down
    remove_index :projects, :path
  end
end
