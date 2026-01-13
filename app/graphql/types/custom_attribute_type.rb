# frozen_string_literal: true

module Types
  # rubocop: disable Gitlab/BoundedContexts -- generic type shared across Projects, Groups, and Users
  # rubocop: disable Graphql/AuthorizeTypes -- authorization at field level on parent type
  class CustomAttributeType < BaseObject
    graphql_name 'CustomAttribute'
    description 'A custom attribute key-value pair. Only available to admins.'

    field :key, GraphQL::Types::String,
      null: false,
      description: 'Key of the custom attribute.'

    field :value, GraphQL::Types::String,
      null: false,
      description: 'Value of the custom attribute.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
  # rubocop: enable Gitlab/BoundedContexts
end
