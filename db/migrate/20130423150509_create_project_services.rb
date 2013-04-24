class CreateProjectServices < ActiveRecord::Migration
  def change
    create_table :project_services do |t|
      t.string :service_hook_name
      t.integer :project_id
      t.boolean :active
      t.text :data

      t.timestamps
    end
    add_index :project_services, :project_id
  end
end
