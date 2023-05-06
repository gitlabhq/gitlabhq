# frozen_string_literal: true

module Types
  module MergeRequests
    class DetailedMergeStatusEnum < BaseEnum
      graphql_name 'DetailedMergeStatus'
      description 'Detailed representation of whether a GitLab merge request can be merged.'

      value 'UNCHECKED',
            value: :unchecked,
            description: 'Merge status has not been checked.'
      value 'CHECKING',
            value: :checking,
            description: 'Currently checking for mergeability.'
      value 'MERGEABLE',
            value: :mergeable,
            description: 'Branch can be merged.'
      value 'BROKEN_STATUS',
            value: :broken_status,
            description: 'Can not merge the source into the target branch, potential conflict.'
      value 'CI_MUST_PASS',
            value: :ci_must_pass,
            description: 'Pipeline must succeed before merging.'
      value 'CI_STILL_RUNNING',
            value: :ci_still_running,
            description: 'Pipeline is still running.'
      value 'DISCUSSIONS_NOT_RESOLVED',
            value: :discussions_not_resolved,
            description: 'Discussions must be resolved before merging.'
      value 'DRAFT_STATUS',
            value: :draft_status,
            description: 'Merge request must not be draft before merging.'
      value 'NOT_OPEN',
            value: :not_open,
            description: 'Merge request must be open before merging.'
      value 'NOT_APPROVED',
            value: :not_approved,
            description: 'Merge request must be approved before merging.'
      value 'BLOCKED_STATUS',
            value: :merge_request_blocked,
            description: 'Merge request is blocked by another merge request.'
      value 'POLICIES_DENIED',
            value: :policies_denied,
            description: 'There are denied policies for the merge request.'
      value 'EXTERNAL_STATUS_CHECKS',
            value: :status_checks_must_pass,
            description: 'Status checks must pass.'
      value 'PREPARING',
            value: :preparing,
            description: 'Merge request diff is being created.'
    end
  end
end
