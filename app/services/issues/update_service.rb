module Issues
  class UpdateService < BaseService
    def execute(issue)
      state = params.delete('state_event')

      case state
      when 'reopen'
        Issues::ReopenService.new(project, current_user, {}).execute(issue)
      when 'close'
        Issues::CloseService.new(project, current_user, {}).execute(issue)
      end

      if params.present? && issue.update_attributes(params)
        issue.reset_events_cache

        if issue.is_being_reassigned?
          notification_service.reassigned_issue(issue, current_user)
          create_assignee_note(issue)
        end

        issue.notice_added_references(issue.project, current_user)
        execute_hooks(issue)
      end

      issue
    end
  end
end
