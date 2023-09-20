# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      class StatusEnum < BaseEnum
        graphql_name 'CodequalityReportsComparerReportStatus'
        description 'Report comparison status'

        value 'SUCCESS', value: 'success', description: 'Report successfully generated.'
        value 'FAILED', value: 'failed', description: 'Report failed to generate.'
        value 'NOT_FOUND', value: 'not_found', description: 'Head report or base report not found.'
      end
    end
  end
end
