module Issues
  class CreateService < Issues::BaseService
    def execute
      @request = params.delete(:request)
      @api = params.delete(:api)

      @issue = project.issues.new

      create(@issue)
    end

    def before_create(issuable)
      issuable.spam = spam_service.check(@api)
    end

    def after_create(issuable)
      event_service.open_issue(issuable, current_user)
      notification_service.new_issue(issuable, current_user)
      todo_service.new_issue(issuable, current_user)
      user_agent_detail_service.create
    end

    private

    def spam_service
      SpamService.new(@issue, @request)
    end

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, @request)
    end
  end
end
