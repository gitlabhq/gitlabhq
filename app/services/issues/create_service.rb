# frozen_string_literal: true

module Issues
  class CreateService < Issues::BaseService
    include SpamCheckService
    include ResolveDiscussions

    def execute
      @issue = BuildService.new(project, current_user, params).execute

      filter_spam_check_params
      filter_resolve_discussion_params

      create(@issue)
    end

    def before_create(issue)
      spam_check(issue, current_user)
      issue.move_to_end

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      issue.run_after_commit do
        NewIssueWorker.perform_async(issue.id, user.id)
      end
    end

    def after_create(issuable)
      todo_service.new_issue(issuable, current_user)
      user_agent_detail_service.create
      resolve_discussions_with_issue(issuable)

      super
    end

    def resolve_discussions_with_issue(issue)
      return if discussions_to_resolve.empty?

      Discussions::ResolveService.new(project, current_user,
                                      merge_request: merge_request_to_resolve_discussions_of,
                                      follow_up_issue: issue)
        .execute(discussions_to_resolve)
    end

    private

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, @request)
    end
  end
end

Issues::CreateService.prepend_if_ee('EE::Issues::CreateService')
