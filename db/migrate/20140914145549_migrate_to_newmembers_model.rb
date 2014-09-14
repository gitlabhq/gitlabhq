class MigrateToNewmembersModel < ActiveRecord::Migration
  def up
    UsersGroup.find_each(batch_size: 500) do |user_group|
      GroupMember.create(
        user_id: user_group.user_id,
        source_type: 'Group',
        source_id: user_group.group_id,
        access_level: user_group.group_access,
        notification_level: user_group.notification_level,
      )

      print '.'
    end

    UsersProject.find_each(batch_size: 500) do |user_project|
      ProjectMember.create(
        user_id: user_project.user_id,
        source_type: 'Project',
        source_id: user_project.project_id,
        access_level: user_project.project_access,
        notification_level: user_project.notification_level,
      )

      print '.'
    end
  end

  def down
    Member.destroy_all
  end
end
