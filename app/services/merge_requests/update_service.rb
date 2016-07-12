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

      merge_request.merge_params['force_remove_source_branch'] = params.delete(:force_remove_source_branch)
      old_approvers = merge_request.overall_approvers.to_a

      update(merge_request)

      new_approvers = merge_request.overall_approvers.to_a - old_approvers

      if new_approvers.any?
        todo_service.add_merge_request_approvers(merge_request, new_approvers)
        notification_service.add_merge_request_approvers(merge_request, new_approvers, current_user)
      end

      merge_request
    end

    def handle_changes(merge_request, old_labels: [])
      if has_changes?(merge_request, old_labels: old_labels)
        todo_service.mark_pending_todos_as_done(merge_request, current_user)
      end

      if merge_request.previous_changes.include?('title') ||
         merge_request.previous_changes.include?('description')
        todo_service.update_merge_request(merge_request, current_user)
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
        todo_service.reassigned_merge_request(merge_request, current_user)
      end

      if merge_request.previous_changes.include?('target_branch') ||
          merge_request.previous_changes.include?('source_branch')
        merge_request.mark_as_unchecked
      end

      added_labels = merge_request.labels - old_labels
      if added_labels.present?
        notification_service.relabeled_merge_request(
          merge_request,
          added_labels,
          current_user
        )
      end
    end

    def reopen_service
      MergeRequests::ReopenService
    end

    def close_service
      MergeRequests::CloseService
    end
  end
end
