# frozen_string_literal: true

module MergeRequests
  class HandleAssigneesChangeService < MergeRequests::BaseService
    def async_execute(merge_request, old_assignees, options = {})
      MergeRequests::HandleAssigneesChangeWorker
        .perform_async(
          merge_request.id,
          current_user.id,
          old_assignees.map(&:id),
          options.stringify_keys # see: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1090
        )
    end

    def execute(merge_request, old_assignees, options = {})
      create_assignee_note(merge_request, old_assignees)
      notification_service.async.reassigned_merge_request(merge_request, current_user, old_assignees.to_a)
      Gitlab::ResourceEvents::AssignmentEventRecorder.new(parent: merge_request, old_assignees: old_assignees).record
      todo_service.reassigned_assignable(merge_request, current_user, old_assignees)

      new_assignees = merge_request.assignees - old_assignees
      merge_request_activity_counter.track_users_assigned_to_mr(users: new_assignees)
      merge_request_activity_counter.track_assignees_changed_action(user: current_user)

      if current_user.merge_request_dashboard_enabled?
        invalidate_cache_counts(merge_request, users: merge_request.assignees)
      end

      invalidate_cache_counts(merge_request, users: old_assignees)

      trigger_user_merge_request_updated(merge_request)

      execute_assignees_hooks(merge_request, old_assignees) if options['execute_hooks']
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

MergeRequests::HandleAssigneesChangeService.prepend_mod_with('MergeRequests::HandleAssigneesChangeService')
