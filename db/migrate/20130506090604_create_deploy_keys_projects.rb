class CreateDeployKeysProjects < ActiveRecord::Migration
  def change
    create_table :deploy_keys_projects do |t|
      t.integer :deploy_key_id, null: false
      t.integer :project_id, null: false

      t.timestamps
    end
  end
end
