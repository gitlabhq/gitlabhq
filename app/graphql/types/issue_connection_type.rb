# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class IssueConnectionType < GraphQL::Types::Relay::BaseConnection
    field :count, Integer, null: false,
          description: 'Total count of collection'

    def count
      object.items.size
    end
  end
end
