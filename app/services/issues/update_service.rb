module Issues
  class UpdateService < Issues::BaseService
    def execute(issue)
      case params.delete(:state_event)
      when 'reopen'
        Issues::ReopenService.new(project, current_user, {}).execute(issue)
      when 'close'
        Issues::CloseService.new(project, current_user, {}).execute(issue)
      end

      params[:assignee_id]  = "" if params[:assignee_id] == IssuableFinder::NONE
      params[:milestone_id] = "" if params[:milestone_id] == IssuableFinder::NONE

      filter_params
      old_labels = issue.labels.to_a

      if params.present? && issue.update_attributes(params.merge(updated_by: current_user))
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

        if issue.previous_changes.include?('title')
          create_title_change_note(issue, issue.previous_changes['title'].first)
        end

        issue.create_new_cross_references!(issue.project, current_user)
        execute_hooks(issue, 'update')
      end

      issue
    end
  end
end
