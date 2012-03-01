class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :target_type, :null => true
      t.integer :target_id, :null => true

      t.string :title, :null => true
      t.text :data, :null => true
      t.integer :project_id, :null => true

      t.timestamps
    end
  end
end
