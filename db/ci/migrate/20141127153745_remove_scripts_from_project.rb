class RemoveScriptsFromProject < ActiveRecord::Migration
  def change
    remove_column :projects, :scripts
  end
end