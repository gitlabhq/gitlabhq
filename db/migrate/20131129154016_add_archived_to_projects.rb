class AddArchivedToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :archived, :boolean, default: false, null: false
  end
end
