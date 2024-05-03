# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RecentFailuresType < BaseObject
      graphql_name 'RecentFailures'
      description 'Recent failure history of a test case.'

      connection_type_class Types::CountableConnectionType

      field :count, GraphQL::Types::Int, null: true,
        description: 'Number of times the test case has failed in the past 14 days.'

      field :base_branch, GraphQL::Types::String, null: true,
        description: 'Name of the base branch of the project.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
