module Issues
  class CreateService < Issues::BaseService
    include SpamCheckService
    include ResolveDiscussions

    def execute
      filter_spam_check_params
      filter_resolve_discussion_params

      issue_attributes = params.merge(
        merge_request_for_resolving_discussions: merge_request_for_resolving_discussions_iid,
        discussion_to_resolve: discussion_to_resolve_id
      )

      @issue = BuildService.new(project, current_user, issue_attributes).execute

      create(@issue)
    end

    def before_create(issue)
      spam_check(issue, current_user)
      issue.move_to_end
    end

    def after_create(issuable)
      event_service.open_issue(issuable, current_user)
      notification_service.new_issue(issuable, current_user)
      todo_service.new_issue(issuable, current_user)
      user_agent_detail_service.create
      resolve_discussions_with_issue(issuable)
    end

    private

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, @request)
    end
  end
end
