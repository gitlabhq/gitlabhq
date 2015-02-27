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

      old_labels = issue.labels.to_a

      if params.present? && issue.update_attributes(params.except(:state_event,
                                                                  :task_num))
        issue.reset_events_cache

        if issue.labels != old_labels
          create_labels_note(
            issue, issue.labels - old_labels, old_labels - issue.labels)
        end

        if issue.previous_changes.include?('milestone_id')
          create_milestone_note(issue)
        end

        if issue.previous_changes.include?('assignee_id')
          create_assignee_note(issue)
          notification_service.reassigned_issue(issue, current_user)
        end

        issue.notice_added_references(issue.project, current_user)
        execute_hooks(issue, 'update')
      end

      issue
    end
  end
end
