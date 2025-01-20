# frozen_string_literal: true

module Types
  module Repositories
    class TagType < BaseObject
      graphql_name 'Tag'

      authorize :read_code

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the tag.'

      field :message,
        GraphQL::Types::String,
        null: true,
        description: 'Tagging message.'

      field :commit, Types::Repositories::CommitType,
        null: true, resolver: Resolvers::Repositories::RefCommitResolver,
        description: 'Commit for the tag.'
    end
  end
end
