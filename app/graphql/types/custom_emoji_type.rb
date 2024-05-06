# frozen_string_literal: true

module Types
  class CustomEmojiType < BaseObject
    graphql_name 'CustomEmoji'
    description 'A custom emoji uploaded by user'

    authorize :read_custom_emoji

    connection_type_class Types::CountableConnectionType

    expose_permissions Types::PermissionTypes::CustomEmoji

    field :id, ::Types::GlobalIDType[::CustomEmoji],
      null: false,
      description: 'ID of the emoji.'

    field :name, GraphQL::Types::String,
      null: false,
      description: 'Name of the emoji.'

    field :url, GraphQL::Types::String,
      null: false,
      description: 'Link to file of the emoji.'

    field :external, GraphQL::Types::Boolean,
      null: false,
      description: 'Whether the emoji is an external link.'

    field :created_at, Types::TimeType,
      null: false,
      description: 'Timestamp of when the custom emoji was created.'
  end
end
