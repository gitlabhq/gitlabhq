class CreateEventTable < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :project_id
      t.integer :user_id
      t.integer :is_admin
      t.text    :description

      t.timestamps
      
      t.index :created_at
      t.index :is_admin
      t.index :project_id
    end
  end
end
