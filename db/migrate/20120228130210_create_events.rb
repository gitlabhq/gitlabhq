class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :data_type, :null => true
      t.string :data_id, :null => true
      t.string :title, :null => true
      t.text :data, :null => true
      t.integer :project_id, :null => true

      t.timestamps
    end
  end
end
