class AddAnonCloneToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :anon_clone, :boolean, :default => false, :null => false
  end
end
