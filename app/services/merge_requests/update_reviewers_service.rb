# frozen_string_literal: true

module MergeRequests
  class UpdateReviewersService < UpdateService
    def execute(merge_request)
      return merge_request unless current_user&.can?(:set_merge_request_metadata, merge_request)

      old_reviewers = merge_request.reviewers.to_a
      old_ids = old_reviewers.map(&:id)
      new_ids = new_user_ids(merge_request, update_attrs[:reviewer_ids], :reviewers)

      return merge_request if merge_request.errors.any?
      return merge_request if new_ids.size != update_attrs[:reviewer_ids].size
      return merge_request if old_ids.to_set == new_ids.to_set # no-change

      merge_request.update!(update_attrs.merge(reviewer_ids: new_ids))
      handle_reviewers_change(merge_request, old_reviewers)
      resolve_todos_for(merge_request)
      execute_reviewers_hooks(merge_request, old_reviewers)

      merge_request
    end

    private

    def reviewer_ids
      filter_sentinel_values(params.fetch(:reviewer_ids)).first(1)
    end

    def update_attrs
      @attrs ||= { updated_by: current_user, reviewer_ids: reviewer_ids }
    end

    def execute_reviewers_hooks(merge_request, old_reviewers)
      execute_hooks(
        merge_request,
        'update',
        old_associations: { reviewers: old_reviewers }
      )
    end
  end
end

MergeRequests::UpdateReviewersService.prepend_mod
