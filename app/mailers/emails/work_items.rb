# frozen_string_literal: true

module Emails
  module WorkItems
    def import_work_items_csv_email(user_id, project_id, results)
      @user = User.find(user_id)
      @project = Project.find(project_id)
      @results = results

      email_with_layout(
        to: @user.notification_email_for(@project),
        subject: subject('Imported work items'))
    end
  end
end
