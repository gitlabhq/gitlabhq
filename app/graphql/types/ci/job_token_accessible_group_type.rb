# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- this type does not need authorization
  module Ci
    class JobTokenAccessibleGroupType < BaseObject
      graphql_name 'CiJobTokenAccessibleGroup'

      description 'Group that can access the current project by authenticating with a CI/CD job token.'

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Avatar URL of the group.'

      field :full_path, GraphQL::Types::ID, null: false,
        description: 'Full path of the group.'

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the group.'

      field :name, GraphQL::Types::String, null: false,
        description: 'Name of the group.'

      field :path, GraphQL::Types::String, null: false,
        description: 'Path of the group.'

      field :web_url, GraphQL::Types::String, null: true,
        description: 'Web URL of the group.'

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
