class RemoveDeprecatedTables < ActiveRecord::Migration
  def up
    drop_table :user_teams
    drop_table :user_team_project_relationships
    drop_table :user_team_user_relationships
  end

  def down
    raise 'No rollback for this migration'
  end
end
