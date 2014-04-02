module Issues
  class UpdateService < BaseService
    def execute(issue)
      if issue.update_attributes(params)
        issue.reset_events_cache

        if issue.is_being_reassigned?
          notification.reassigned_issue(issue, current_user)
          create_assignee_note(issue)
        end

        issue.notice_added_references(issue.project, current_user)
        execute_hooks(issue)
      end

      issue
    end
  end
end
