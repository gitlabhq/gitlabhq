class BuildMissingServices < ActiveRecord::Migration
  def up
    Project.find_each do |project|
      # Slack service creation
      slack_service = select_one("SELECT id FROM services WHERE type='SlackService' AND project_id = #{project.id}")
      
      unless slack_service
        execute("INSERT INTO services (type, project_id, active, properties, created_at, updated_at) \
            VALUES ('SlackService', '#{project.id}', false, '{}', NOW(), NOW())")
      end

      # Mail service creation
      mail_service = select_one("SELECT id FROM services WHERE type='MailService' AND project_id = #{project.id}")
      
      unless mail_service
        execute("INSERT INTO services (type, project_id, active, properties, created_at, updated_at) \
            VALUES ('MailService', '#{project.id}', true, '{}', NOW(), NOW())")
      end
    end
  end
end
