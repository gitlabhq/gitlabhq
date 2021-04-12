# frozen_string_literal: true

module MergeRequests
  class HandleAssigneesChangeService < MergeRequests::BaseService
    def async_execute(merge_request, old_assignees, options = {})
      if Feature.enabled?(:async_handle_merge_request_assignees_change, merge_request.target_project, default_enabled: :yaml)
        MergeRequests::HandleAssigneesChangeWorker
          .perform_async(
            merge_request.id,
            current_user.id,
            old_assignees.map(&:id),
            options
          )
      else
        execute(merge_request, old_assignees, options)
      end
    end

    def execute(merge_request, old_assignees, options = {})
      create_assignee_note(merge_request, old_assignees)
      notification_service.async.reassigned_merge_request(merge_request, current_user, old_assignees.to_a)
      todo_service.reassigned_assignable(merge_request, current_user, old_assignees)

      new_assignees = merge_request.assignees - old_assignees
      merge_request_activity_counter.track_users_assigned_to_mr(users: new_assignees)
      merge_request_activity_counter.track_assignees_changed_action(user: current_user)

      execute_assignees_hooks(merge_request, old_assignees) if options[:execute_hooks]
    end

    private

    def execute_assignees_hooks(merge_request, old_assignees)
      execute_hooks(
        merge_request,
        'update',
        old_associations: { assignees: old_assignees }
      )
    end
  end
end

MergeRequests::HandleAssigneesChangeService.prepend_if_ee('EE::MergeRequests::HandleAssigneesChangeService')
