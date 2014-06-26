module Issues
  class CreateService < Issues::BaseService
    def execute
      issue = project.issues.new(params)
      issue.author = current_user

      if issue.save
        notification_service.new_issue(issue, current_user)
        event_service.open_issue(issue, current_user)
        issue.create_cross_references!(issue.project, current_user)
        execute_hooks(issue, 'open')
      end

      issue
    end
  end
end
