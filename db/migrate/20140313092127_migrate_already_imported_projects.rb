class MigrateAlreadyImportedProjects < ActiveRecord::Migration
  include Gitlab::Database

  def up
    execute("UPDATE projects SET import_status = 'finished' WHERE imported = #{true_value}")
    execute("UPDATE projects SET import_status = 'none' WHERE imported = #{false_value}")
    remove_column :projects, :imported
  end

  def down
    add_column :projects, :imported, :boolean, default: false
    execute("UPDATE projects SET imported = #{true_value} WHERE import_status = 'finished'")
  end
end
