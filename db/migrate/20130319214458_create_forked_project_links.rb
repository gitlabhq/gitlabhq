class CreateForkedProjectLinks < ActiveRecord::Migration
  def change
    create_table :forked_project_links do |t|
      t.integer :forked_to_project_id, null: false
      t.integer :forked_from_project_id, null: false

      t.timestamps
    end
    add_index :forked_project_links, :forked_to_project_id, unique: true
  end
end
