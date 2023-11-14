# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      # rubocop: disable Graphql/AuthorizeTypes -- Parent node applies authorization
      class ReportType < BaseObject
        graphql_name 'CodequalityReportsComparerReport'

        description 'Represents compared code quality report.'

        field :status,
          type: CodequalityReportsComparer::StatusEnum,
          null: false,
          description: 'Status of report.'

        field :new_errors,
          type: [CodequalityReportsComparer::DegradationType],
          null: false,
          description: 'New code quality degradations.'

        field :resolved_errors,
          type: [CodequalityReportsComparer::DegradationType],
          null: true,
          description: 'Resolved code quality degradations.'

        field :existing_errors,
          type: [CodequalityReportsComparer::DegradationType],
          null: true,
          description: 'All code quality degradations.'

        field :summary,
          type: CodequalityReportsComparer::SummaryType,
          null: false,
          description: 'Codequality report summary.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
