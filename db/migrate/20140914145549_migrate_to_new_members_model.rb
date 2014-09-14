class MigrateToNewMembersModel < ActiveRecord::Migration
  def up
    execute "INSERT INTO members ( user_id, source_id, source_type, access_level, notification_level, type ) SELECT user_id, group_id, 'Namespace', group_access, notification_level, 'GroupMember' FROM users_groups"
    execute "INSERT INTO members ( user_id, source_id, source_type, access_level, notification_level, type ) SELECT user_id, project_id, 'Project', project_access, notification_level, 'ProjectMember' FROM users_projects"
  end

  def down
    Member.delete_all
  end
end

