# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module Connections
        # rubocop: disable Graphql/AuthorizeTypes -- counts are looking up authorized data already
        class ClosingMergeRequestsConnectionType < GraphQL::Types::Relay::BaseConnection
          graphql_name 'ClosingMergeRequestsConnectionType'
          description 'Connection details for closing merge requests data'

          field :count,
            null: true,
            description: 'Number of merge requests that close the work item on merge.',
            resolver: Resolvers::MergeRequestsCountResolver
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end
