# frozen_string_literal: true

module Types
  module MergeRequests
    class ConflictStatusEnum < BaseEnum
      graphql_name 'MergeRequestConflictStatus'
      description 'Status of conflict file availability for a merge request.'

      value 'HAS_CONFLICTS',
        value: :has_conflicts,
        description: 'Merge request has conflicts. ' \
          'conflictFiles may still be null if files cannot be fetched (for example, binary files).'
      value 'NO_CONFLICTS',
        value: :no_conflicts,
        description: 'Merge request can be merged; no conflicts exist.'
      value 'UNCHECKED',
        value: :unchecked,
        description: 'Mergeability has not been checked yet; conflicts cannot be determined.'
      value 'BRANCH_MISSING',
        value: :branch_missing,
        description: 'Source or target branch is missing, or diff refs are incomplete.'
      value 'NO_PUSH_ACCESS',
        value: :no_push_access,
        description: 'Current user cannot push to the source branch.'
    end
  end
end
