# frozen_string_literal: true

module Types
  class CustomEmojiType < BaseObject
    graphql_name 'CustomEmoji'
    description 'A custom emoji uploaded by user'

    authorize :read_custom_emoji

    field :id, ::Types::GlobalIDType[::CustomEmoji],
          null: false,
          description: 'The ID of the emoji'

    field :name, GraphQL::STRING_TYPE,
          null: false,
          description: 'The name of the emoji'

    field :url, GraphQL::STRING_TYPE,
          null: false,
          method: :file,
          description: 'The link to file of the emoji'

    field :external, GraphQL::BOOLEAN_TYPE,
          null: false,
          description: 'Whether the emoji is an external link'
  end
end
