class RemoveNotificationSettingsForDeletedProjects < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      DELETE FROM notification_settings
      WHERE notification_settings.source_type = 'Project'
        AND NOT EXISTS (
              SELECT *
              FROM projects
              WHERE projects.id = notification_settings.source_id
            )
    SQL
  end
end
