class CreateUsersProjects < ActiveRecord::Migration
  def change
    create_table :users_projects do |t|
      t.integer :user_id, :null => false
      t.integer :project_id, :null => false
      t.boolean :read,  :default => false
      t.boolean :write, :default => false
      t.boolean :admin, :default => false

      t.timestamps
    end
  end
end
