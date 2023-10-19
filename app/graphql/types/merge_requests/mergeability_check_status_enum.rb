# frozen_string_literal: true

module Types
  module MergeRequests
    class MergeabilityCheckStatusEnum < BaseEnum
      graphql_name 'MergeabilityCheckStatus'
      description 'Representation of whether a mergeability check passed, failed or is inactive.'

      value 'SUCCESS',
        value: 'success',
        description: 'Mergeability check has passed.'

      value 'FAILED',
        value: 'failed',
        description: 'Mergeability check has failed. The merge request cannot be merged.'

      value 'INACTIVE',
        value: 'inactive',
        description: 'Mergeability check is disabled via settings.'
    end
  end
end
