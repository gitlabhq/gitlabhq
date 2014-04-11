class CreateProjectTemplates < ActiveRecord::Migration
  def change
    create_table :project_templates do |t|
      t.string :name, limit: 100
      t.string :save_name, limit: 200, null: false
      t.text :description, limit: 750
      t.string :upload, limit: 400
      t.integer :state, limit: 1, default: 0

      t.timestamps
    end

    add_index :project_templates, :name, unique: true
  end
end
