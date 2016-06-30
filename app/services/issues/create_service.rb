module Issues
  class CreateService < Issues::BaseService
    def execute
      issue = project.issues.new
      request = params.delete(:request)
      api = params.delete(:api)

      issue.spam = spam_check_service.execute(request, api)

      create(issue)
    end

    def handle_creation(issuable)
      event_service.open_issue(issuable, current_user)
      notification_service.new_issue(issuable, current_user)
      todo_service.new_issue(issuable, current_user)
    end

    private

    def spam_check_service
      SpamCheckService.new(project, current_user, params)
    end
  end
end
