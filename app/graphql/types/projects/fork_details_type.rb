# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable Graphql/AuthorizeTypes
    class ForkDetailsType < BaseObject
      graphql_name 'ForkDetails'
      description 'Details of the fork project compared to its upstream project.'

      field :ahead, GraphQL::Types::Int,
            null: true,
            description: 'Number of commits ahead of upstream.'

      field :behind, GraphQL::Types::Int,
            null: true,
            description: 'Number of commits behind upstream.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
