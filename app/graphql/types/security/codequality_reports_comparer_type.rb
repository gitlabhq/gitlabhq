# frozen_string_literal: true

module Types
  module Security
    # rubocop: disable Graphql/AuthorizeTypes -- The resolver authorizes the request
    class CodequalityReportsComparerType < BaseObject
      graphql_name 'CodequalityReportsComparer'

      description 'Represents reports comparison for code quality.'

      field :status,
        type: CodequalityReportsComparer::ReportGenerationStatusEnum,
        null: true,
        description: 'Compared codequality report generation status.'

      field :report,
        type: CodequalityReportsComparer::ReportType,
        null: true,
        hash_key: :data,
        description: 'Compared codequality report.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
