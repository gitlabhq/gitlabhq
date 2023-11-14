# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      class ReportGenerationStatusEnum < BaseEnum
        graphql_name 'CodequalityReportsComparerReportGenerationStatus'
        description 'Represents the generation status of the compared codequality report.'

        value 'PARSED', value: :parsed, description: 'Report was generated.'
        value 'PARSING', value: :parsing, description: 'Report is being generated.'
        value 'ERROR', value: :error, description: 'An error happened while generating the report.'
      end
    end
  end
end
