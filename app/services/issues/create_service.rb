module Issues
  class CreateService < Issues::BaseService
    def execute
      @request = params.delete(:request)
      @api = params.delete(:api)

      issue_attributes = params.merge(merge_request_for_resolving_discussions: merge_request_for_resolving_discussions)
      @issue = BuildService.new(project, current_user, issue_attributes).execute

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

      if merge_request_for_resolving_discussions.try(:discussions_can_be_resolved_by?, current_user)
        resolve_discussions_in_merge_request(issuable)
      end
    end

    def resolve_discussions_in_merge_request(issue)
      Discussions::ResolveService.new(project, current_user,
                                      merge_request: merge_request_for_resolving_discussions,
                                      follow_up_issue: issue).
          execute(merge_request_for_resolving_discussions.resolvable_discussions)
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
