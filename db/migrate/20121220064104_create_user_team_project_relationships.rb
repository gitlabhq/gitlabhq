class CreateUserTeamProjectRelationships < ActiveRecord::Migration
  def change
    create_table :user_team_project_relationships do |t|
      t.integer :project_id
      t.integer :user_team_id
      t.integer :greatest_access

      t.timestamps
    end
  end
end
