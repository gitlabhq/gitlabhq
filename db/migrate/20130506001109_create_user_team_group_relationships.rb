class CreateUserTeamGroupRelationships < ActiveRecord::Migration
  def change
    create_table :user_team_group_relationships do |t|
      t.integer :user_team_id
      t.integer :group_id
      t.integer :greatest_access

      t.timestamps
    end
  end
end
