module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      state = params[:state_event]

      case state
      when 'reopen'
        Issues::ReopenService.new(project, current_user, {}).execute(issue)
      when 'close'
        Issues::CloseService.new(project, current_user, {}).execute(issue)
      when 'task_check'
        issue.update_nth_task(params[:task_num].to_i, true)
      when 'task_uncheck'
        issue.update_nth_task(params[:task_num].to_i, false)
      end

      if params.present? && issue.update_attributes(params.except(:state_event,
                                                                  :task_num))
        issue.reset_events_cache

        if issue.previous_changes.include?('milestone_id')
          create_milestone_note(issue)
        end

        if issue.previous_changes.include?('assignee_id')
          notification_service.reassigned_issue(issue, current_user)
          create_assignee_note(issue)
        end

        issue.notice_added_references(issue.project, current_user)
        execute_hooks(issue, 'update')
      end

      issue
    end
  end
end
