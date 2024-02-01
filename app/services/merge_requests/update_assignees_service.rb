# frozen_string_literal: true

module MergeRequests
  class UpdateAssigneesService < UpdateService
    # a stripped down service that only does what it must to update the
    # assignees, and knows that it does not have to check for other updates.
    # This saves a lot of queries for irrelevant things that cannot possibly
    # change in the execution of this service.
    def execute(merge_request)
      return merge_request unless current_user&.can?(:set_merge_request_metadata, merge_request)

      old_assignees = merge_request.assignees.to_a
      old_ids = old_assignees.map(&:id)
      new_ids = new_user_ids(merge_request, update_attrs[:assignee_ids], :assignees)

      return merge_request if merge_request.errors.any?
      return merge_request if new_ids.size != update_attrs[:assignee_ids].size
      return merge_request if old_ids.to_set == new_ids.to_set # no-change

      attrs = update_attrs.merge(assignee_ids: new_ids)

      merge_request.update(**attrs)

      return merge_request unless merge_request.valid?

      # Defer the more expensive operations (handle_assignee_changes) to the background
      MergeRequests::HandleAssigneesChangeService
        .new(project: project, current_user: current_user)
        .async_execute(merge_request, old_assignees, execute_hooks: true)

      merge_request
    end

    private

    def assignee_ids
      filter_sentinel_values(params.fetch(:assignee_ids)).first(1)
    end

    def params
      ps = super

      # allow either assignee_id or assignee_ids, preferring assignee_id if passed.
      { assignee_ids: ps.key?(:assignee_id) ? Array.wrap(ps[:assignee_id]) : ps[:assignee_ids] }
    end

    def update_attrs
      @attrs ||= { updated_at: Time.current, updated_by: current_user, assignee_ids: assignee_ids }
    end
  end
end

MergeRequests::UpdateAssigneesService.prepend_mod_with('MergeRequests::UpdateAssigneesService')
