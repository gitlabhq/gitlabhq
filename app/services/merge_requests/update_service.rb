require_relative 'base_service'
require_relative 'reopen_service'
require_relative 'close_service'

module MergeRequests
  class UpdateService < MergeRequests::BaseService
    def execute(merge_request)
      # We don't allow change of source/target projects and source branch
      # after merge request was created
      params.except!(:source_project_id)
      params.except!(:target_project_id)
      params.except!(:source_branch)

      case params.delete(:state_event)
      when 'reopen'
        MergeRequests::ReopenService.new(project, current_user, {}).execute(merge_request)
      when 'close'
        MergeRequests::CloseService.new(project, current_user, {}).execute(merge_request)
      end

      params[:assignee_id]  = "" if params[:assignee_id] == IssuableFinder::NONE
      params[:milestone_id] = "" if params[:milestone_id] == IssuableFinder::NONE

      filter_params
      old_labels = merge_request.labels.to_a

      if params.present? && merge_request.update_attributes(params.merge(updated_by: current_user))
        merge_request.reset_events_cache

        if merge_request.labels != old_labels
          create_labels_note(
            merge_request,
            merge_request.labels - old_labels,
            old_labels - merge_request.labels
          )
        end

        if merge_request.previous_changes.include?('target_branch')
          create_branch_change_note(merge_request, 'target',
                                    merge_request.previous_changes['target_branch'].first,
                                    merge_request.target_branch)
        end

        if merge_request.previous_changes.include?('milestone_id')
          create_milestone_note(merge_request)
        end

        if merge_request.previous_changes.include?('assignee_id')
          create_assignee_note(merge_request)
          notification_service.reassigned_merge_request(merge_request, current_user)
        end

        if merge_request.previous_changes.include?('title')
          create_title_change_note(merge_request, merge_request.previous_changes['title'].first)
        end

        if merge_request.previous_changes.include?('target_branch') ||
            merge_request.previous_changes.include?('source_branch')
          merge_request.mark_as_unchecked
        end

        merge_request.create_new_cross_references!(merge_request.project, current_user)
        execute_hooks(merge_request, 'update')
      end

      merge_request
    end
  end
end
