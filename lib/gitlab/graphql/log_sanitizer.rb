# frozen_string_literal: true

module Gitlab
  module Graphql
    # Redacts a query's variables and document before either reaches graphql_json.log.
    module LogSanitizer
      MUTATION_REGEXP = /^mutation/

      def self.variables(variables, operation_name)
        filtered = ActiveSupport::ParameterFilter
          .new(::Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer::FILTER_PARAMETERS)
          .filter(variables)

        ::Gitlab::Graphql::VariableFilters::Registry.filter(filtered, operation_name)&.to_s
      end

      def self.query_string(query)
        return query.query_string unless MUTATION_REGEXP.match?(query.query_string)

        query.sanitized_query_string
      end
    end
  end
end
