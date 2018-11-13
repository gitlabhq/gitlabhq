# rubocop:disable all
class CreateUsersStarProjects < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :users_star_projects do |t|
      t.integer :project_id, null: false
      t.integer :user_id, null: false
      t.timestamps null: true
    end
    add_index :users_star_projects, :user_id
    add_index :users_star_projects, :project_id
    add_index :users_star_projects, [:user_id, :project_id], unique: true

    add_column :projects, :star_count, :integer, default: 0, null: false
    add_index :projects, :star_count, using: :btree
  end
end
