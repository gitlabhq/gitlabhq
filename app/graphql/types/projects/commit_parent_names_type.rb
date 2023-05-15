# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable Graphql/AuthorizeTypes
    class CommitParentNamesType < BaseObject
      graphql_name 'CommitParentNames'

      field :names, [GraphQL::Types::String], null: true, description: 'Names of the commit parent (branch or tag).'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
