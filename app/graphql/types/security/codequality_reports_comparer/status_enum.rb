# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      class StatusEnum < BaseEnum
        graphql_name 'CodequalityReportsComparerStatus'
        description 'Represents the state of the code quality report.'

        value 'SUCCESS', value: 'success', description: 'No degradations found in the head pipeline report.'
        value 'FAILED', value: 'failed', description: 'Report generated and there are new code quality degradations.'
        value 'NOT_FOUND', value: 'not_found', description: 'Head report or base report not found.'
      end
    end
  end
end
