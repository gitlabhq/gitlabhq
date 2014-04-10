class MigrateAlreadyImportedProjects < ActiveRecord::Migration
  def up
    Project.where(imported: true).update_all(import_status: "finished")
    Project.where(imported: false).update_all(import_status: "none")
    remove_column :projects, :imported
  end

  def down
    add_column :projects, :imported, :boolean, default: false
    Project.where(import_status: 'finished').update_all(imported: true)
  end
end
