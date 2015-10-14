module Issues
  class CreateService < Issues::BaseService
    def execute
      filter_params
      label_params = params[:label_ids]
      issue = project.issues.new(params.except(:label_ids))
      issue.author = current_user

      if issue.save
        issue.update_attributes(label_ids: label_params)
        notification_service.new_issue(issue, current_user)
        event_service.open_issue(issue, current_user)
        issue.create_cross_references!(current_user)
        execute_hooks(issue, 'open')
      end

      issue
    end
  end
end
