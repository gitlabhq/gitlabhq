# frozen_string_literal: true

module Issues
  class CreateService < Issues::BaseService
    include SpamCheckMethods
    include ResolveDiscussions

    def execute(skip_system_notes: false)
      @issue = BuildService.new(project, current_user, params).execute

      filter_spam_check_params
      filter_resolve_discussion_params

      create(@issue, skip_system_notes: skip_system_notes)
    end

    def before_create(issue)
      spam_check(issue, current_user, action: :create)

      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      issue.run_after_commit do
        NewIssueWorker.perform_async(issue.id, user.id)
        IssuePlacementWorker.perform_async(nil, issue.project_id)
      end
    end

    def after_create(issue)
      add_incident_label(issue)
      todo_service.new_issue(issue, current_user)
      user_agent_detail_service.create
      resolve_discussions_with_issue(issue)
      delete_milestone_total_issue_counter_cache(issue.milestone)
      track_incident_action(current_user, issue, :incident_created)

      super
    end

    def resolve_discussions_with_issue(issue)
      return if discussions_to_resolve.empty?

      Discussions::ResolveService.new(project, current_user,
                                      one_or_more_discussions: discussions_to_resolve,
                                      follow_up_issue: issue).execute
    end

    private

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, @request)
    end
  end
end

Issues::CreateService.prepend_if_ee('EE::Issues::CreateService')
