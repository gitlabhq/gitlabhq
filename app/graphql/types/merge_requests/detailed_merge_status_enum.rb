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
      value 'COMMITS_STATUS',
        value: :commits_status,
        description: 'Source branch exists and contains commits.'
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
        description: 'Merge request dependencies must be merged.'
      value 'EXTERNAL_STATUS_CHECKS',
        value: :status_checks_must_pass,
        description: 'Status checks must pass.'
      value 'PREPARING',
        value: :preparing,
        description: 'Merge request diff is being created.'
      value 'JIRA_ASSOCIATION',
        value: :jira_association_missing,
        description: 'Either the title or description must reference a Jira issue.'
      value 'CONFLICT',
        value: :conflict,
        description: 'There are conflicts between the source and target branches.'
      value 'NEED_REBASE',
        value: :need_rebase,
        description: 'Merge request needs to be rebased.'
      value 'APPROVALS_SYNCING',
        value: :approvals_syncing,
        description: 'Merge request approvals currently syncing.'
      value 'LOCKED_PATHS',
        value: :locked_paths,
        description: 'Merge request includes locked paths.'
      value 'LOCKED_LFS_FILES',
        value: :locked_lfs_files,
        description: 'Merge request includes locked LFS files.'
      value 'MERGE_TIME',
        value: :merge_time,
        description: 'Merge request may not be merged until after the specified time.'
      value 'SECURITY_POLICIES_VIOLATIONS',
        value: :security_policy_violations,
        description: 'All policy rules must be satisfied.'
    end
  end
end

Types::MergeRequests::DetailedMergeStatusEnum.prepend_mod_with('Types::MergeRequests::DetailedMergeStatusEnum')
