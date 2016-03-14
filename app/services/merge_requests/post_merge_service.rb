module MergeRequests
  # PostMergeService class
  #
  # Mark existing merge request as merged
  # and execute all hooks and notifications
  #
  class PostMergeService < MergeRequests::BaseService
    def execute(merge_request)
      close_issues(merge_request)
      merge_request.mark_as_merged
      create_merge_event(merge_request, current_user)
      create_note(merge_request)
      notification_service.merge_mr(merge_request, current_user)
      execute_hooks(merge_request, 'merge')
    end

    private

    def close_issues(merge_request)
      return unless merge_request.target_branch == project.default_branch

      closed_issues = merge_request.closes_issues(current_user)
      closed_issues.each do |issue|
        if can?(current_user, :update_issue, issue)
          Issues::CloseService.new(project, current_user, {}).execute(issue, merge_request)
        end
      end
    end

    def create_merge_event(merge_request, current_user)
      EventCreateService.new.merge_mr(merge_request, current_user)
    end
  end
end
