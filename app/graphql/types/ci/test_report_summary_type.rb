# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class TestReportSummaryType < BaseObject
      graphql_name 'TestReportSummary'
      description 'Test report for a pipeline'

      field :total, Types::Ci::TestReportTotalType, null: false,
        description: 'Total report statistics for a pipeline test report.'

      field :test_suites, Types::Ci::TestSuiteSummaryType.connection_type, null: false,
        description: 'Test suites belonging to a pipeline test report.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
