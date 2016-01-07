class CreateLfsObjectsProjects < ActiveRecord::Migration
  def change
    create_table :lfs_objects_projects do |t|
      t.integer :lfs_object_id, null: false
      t.integer :project_id, null: false

      t.timestamps
    end

    add_index :lfs_objects_projects, :project_id
  end
end
