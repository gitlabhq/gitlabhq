# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- this type does not need authorization
  module Ci
    class JobTokenAccessibleProjectType < BaseObject
      graphql_name 'CiJobTokenAccessibleProject'
      description 'Project that can access the current project by authenticating with a CI/CD job token.'

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the project.'

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the project (without namespace).'

      field :path, GraphQL::Types::String,
        null: false,
        description: 'Path of the project.'

      field :full_path, GraphQL::Types::ID,
        null: false,
        description: 'Full path of the project.'

      field :web_url, GraphQL::Types::String,
        null: true,
        description: 'Web URL of the project.'

      field :avatar_url, GraphQL::Types::String,
        null: true,
        calls_gitaly: true,
        description: 'URL to avatar image file of the project.'

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
