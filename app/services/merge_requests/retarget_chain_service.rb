# frozen_string_literal: true

module MergeRequests
  class RetargetChainService < MergeRequests::BaseService
    MAX_RETARGET_MERGE_REQUESTS = 4

    def execute(merge_request)
      return unless Feature.enabled?(:retarget_merge_requests, merge_request.target_project, default_enabled: :yaml)

      # we can only retarget MRs that are targeting the same project
      return unless merge_request.for_same_project? && merge_request.merged?

      # find another merge requests that
      # - as a target have a current source project and branch
      other_merge_requests = merge_request.source_project
        .merge_requests
        .opened
        .by_target_branch(merge_request.source_branch)
        .preload_source_project
        .limit(MAX_RETARGET_MERGE_REQUESTS)

      other_merge_requests.find_each do |other_merge_request|
        # Update only MRs on projects that we have access to
        next unless can?(current_user, :update_merge_request, other_merge_request.source_project)

        ::MergeRequests::UpdateService
          .new(project: other_merge_request.source_project, current_user: current_user,
               params: {
                 target_branch: merge_request.target_branch,
                 target_branch_was_deleted: true
               })
          .execute(other_merge_request)
      end
    end
  end
end
