# frozen_string_literal: true

module Types
  module Blame
    class GroupsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is presented through `Repository` that has its own authorization
      graphql_name 'Groups'

      field :commit, Types::Repositories::CommitType, null: false,
        description: 'Commit responsible for specified group.'
      field :commit_data, Types::Blame::CommitDataType, null: true,
        description: 'HTML data derived from commit needed to present blame.', calls_gitaly: true
      field :lineno, GraphQL::Types::Int, null: false, description: 'Starting line number for the commit group.'
      field :lines, [GraphQL::Types::String], null: false, description: 'Array of lines added for the commit group.'
      field :previous_path, GraphQL::Types::String, null: true,
        description: "Path to the file in the commit's first parent."
      field :span, GraphQL::Types::Int, null: false,
        description: 'Number of contiguous lines which the blame spans for the commit group.'
    end
  end
end
