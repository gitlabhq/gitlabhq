# rubocop:disable all
class CreateLfsObjectsProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :lfs_objects_projects do |t|
      t.integer :lfs_object_id, null: false
      t.integer :project_id, null: false

      t.timestamps null: true
    end

    add_index :lfs_objects_projects, :project_id
  end
end
