# frozen_string_literal: true

module Types
  module Security
    module CodequalityReportsComparer
      # rubocop: disable Graphql/AuthorizeTypes -- The resolver authorizes the request
      class DegradationType < BaseObject
        graphql_name 'CodequalityReportsComparerReportDegradation'
        description 'Represents a degradation on the compared codequality report.'

        field :description, GraphQL::Types::String,
          null: false,
          description: 'Description of the code quality degradation.'

        field :fingerprint, GraphQL::Types::String,
          null: false,
          description: 'Unique fingerprint to identify the code quality degradation. For example, an MD5 hash.'

        field :severity, Types::Ci::CodeQualityDegradationSeverityEnum,
          null: false,
          description:
            "Severity of the code quality degradation " \
            "(#{::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.keys.map(&:upcase).join(', ')})."

        field :file_path, GraphQL::Types::String,
          null: false,
          description: 'Relative path to the file containing the code quality degradation.'

        field :line, GraphQL::Types::Int,
          null: false,
          description: 'Line on which the code quality degradation occurred.'

        field :web_url, GraphQL::Types::String,
          null: true,
          description: 'URL to the file along with line number.'

        field :engine_name, GraphQL::Types::String,
          null: true,
          description: 'Code quality plugin that reported the degradation.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
