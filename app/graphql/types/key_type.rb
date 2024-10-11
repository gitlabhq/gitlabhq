# frozen_string_literal: true

module Types
  class KeyType < Types::BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'Key'
    description 'Represents an SSH key.'

    implements Types::TodoableInterface

    field :created_at, Types::TimeType, null: false,
      description: 'Timestamp of when the key was created.'
    field :expires_at, Types::TimeType, null: false,
      description: "Timestamp of when the key expires. It's null if it never expires."
    field :id, GraphQL::Types::ID, null: false, description: 'ID of the key.'
    field :key, GraphQL::Types::String, null: false, method: :publishable_key,
      description: 'Public key of the key pair.'
    field :title, GraphQL::Types::String, null: false, description: 'Title of the key.'

    def web_url
      Gitlab::UrlBuilder.build(object)
    end
  end
end
