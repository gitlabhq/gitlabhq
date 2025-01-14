# frozen_string_literal: true

module Types
  module Blame
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupsType < BaseObject
      # This is presented through `Repository` that has its own authorization
      graphql_name 'Groups'

      field :commit, Types::Repositories::CommitType, null: false,
        description: 'Commit responsible for specified group.'
      field :commit_data, Types::Blame::CommitDataType, null: true,
        description: 'HTML data derived from commit needed to present blame.', calls_gitaly: true
      field :lineno, GraphQL::Types::Int, null: false, description: 'Starting line number for the commit group.'
      field :lines, [GraphQL::Types::String], null: false, description: 'Array of lines added for the commit group.'
      field :span, GraphQL::Types::Int, null: false,
        description: 'Number of contiguous lines which the blame spans for the commit group.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
