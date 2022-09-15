# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupVariableConnectionType < GraphQL::Types::Relay::BaseConnection
      field :limit, GraphQL::Types::Int,
        null: false,
        description: 'Maximum amount of group CI/CD variables.'

      def limit
        ::Plan.default.actual_limits.group_ci_variables
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
