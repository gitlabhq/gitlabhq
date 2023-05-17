# frozen_string_literal: true

module Emails
  module WorkItems
    def import_work_items_csv_email(user_id, project_id, results)
      @user = User.find(user_id)
      @project = Project.find(project_id)
      @results = results

      email_with_layout(
        to: @user.notification_email_for(@project.group),
        subject: subject('Imported work items'))
    end

    def export_work_items_csv_email(user, project, csv_data, export_status)
      csv_email(user, project, csv_data, export_status, 'work_items')
    end
  end
end
