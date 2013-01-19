class CreateUserTeamUserRelationships < ActiveRecord::Migration
  def change
    create_table :user_team_user_relationships do |t|
      t.integer :user_id
      t.integer :user_team_id
      t.boolean :group_admin
      t.integer :permission

      t.timestamps
    end
  end
end
