class AddParallelToBuild < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :project_id, null: false
      t.text :commands
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :jobs, :project_id
  end
end
