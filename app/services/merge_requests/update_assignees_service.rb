# frozen_string_literal: true

module MergeRequests
  class UpdateAssigneesService < UpdateService
    # a stripped down service that only does what it must to update the
    # assignees, and knows that it does not have to check for other updates.
    # This saves a lot of queries for irrelevant things that cannot possibly
    # change in the execution of this service.
    def execute(merge_request)
      return merge_request unless current_user&.can?(:update_merge_request, merge_request)

      old_assignees = merge_request.assignees.to_a
      old_ids = old_assignees.map(&:id)
      new_ids = new_assignee_ids(merge_request)

      return merge_request if merge_request.errors.any?
      return merge_request if new_ids.size != update_attrs[:assignee_ids].size
      return merge_request if old_ids.to_set == new_ids.to_set # no-change

      attrs = update_attrs.merge(assignee_ids: new_ids)
      merge_request.update!(**attrs)

      # Defer the more expensive operations (handle_assignee_changes) to the background
      MergeRequests::HandleAssigneesChangeService
        .new(project: project, current_user: current_user)
        .async_execute(merge_request, old_assignees, execute_hooks: true)

      merge_request
    end

    private

    def new_assignee_ids(merge_request)
      # prime the cache - prevent N+1 lookup during authorization loop.
      user_ids = update_attrs[:assignee_ids]
      return [] if user_ids.empty?

      merge_request.project.team.max_member_access_for_user_ids(user_ids)
      User.id_in(user_ids).map do |user|
        if user.can?(:read_merge_request, merge_request)
          user.id
        else
          merge_request.errors.add(
            :assignees,
            "Cannot assign #{user.to_reference} to #{merge_request.to_reference}"
          )
          nil
        end
      end.compact
    end

    def assignee_ids
      params.fetch(:assignee_ids).reject { _1 == 0 }.first(1)
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
