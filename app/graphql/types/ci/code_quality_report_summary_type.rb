# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class CodeQualityReportSummaryType < BaseObject
      graphql_name 'CodeQualityReportSummary'
      description 'Code Quality report for a pipeline'

      field :count, GraphQL::Types::Int, null: true,
        description: 'Total number of Code Quality reports.'
      ::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.each_key do |status|
        field status, GraphQL::Types::Int, null: true,
          description: "Total number of #{status} status."
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
