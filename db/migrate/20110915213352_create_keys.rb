class CreateKeys < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.integer :user_id, :null => false
      t.text :project_id, :null => false
      t.timestamps
    end
  end
end
