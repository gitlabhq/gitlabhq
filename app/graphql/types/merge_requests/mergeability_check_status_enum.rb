# frozen_string_literal: true

module Types
  module MergeRequests
    class MergeabilityCheckStatusEnum < BaseEnum
      graphql_name 'MergeabilityCheckStatus'
      description 'Representation of whether a mergeability check passed, checking, failed or is inactive.'

      value 'SUCCESS',
        value: 'success',
        description: 'Mergeability check has passed.'

      value 'CHECKING',
        value: 'checking',
        description: 'Mergeability check is being checked.'

      value 'FAILED',
        value: 'failed',
        description: 'Mergeability check has failed. The merge request cannot be merged.'

      value 'INACTIVE',
        value: 'inactive',
        description: 'Mergeability check is disabled via settings.'

      value 'WARNING',
        value: 'warning',
        description: 'Mergeability check has passed with a warning.'
    end
  end
end
