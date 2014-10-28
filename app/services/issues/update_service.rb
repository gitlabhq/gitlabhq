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

      old_labels = issue.labels.map{ |label| label }
      if params.present? && issue.update_attributes(params.except(:state_event,
                                                                  :task_num))
        issue.reset_events_cache

        add_label_note(old_labels, issue.labels, issue, true)
        add_label_note(issue.labels, old_labels, issue, false)

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

    private

    def add_label_note(labels1, labels2, issue, removed)
      diff_labels = labels1 - labels2
      create_labels_note(issue, diff_labels, removed) unless diff_labels.empty?
    end

    def update_task(issue, params, checked)
      issue.update_nth_task(params[:task_num].to_i, checked)
      params.except!(:task_num)
    end
  end
end
