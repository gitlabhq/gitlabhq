# frozen_string_literal: true

module Types
  module AwardEmojis
    class AwardEmojiType < BaseObject
      graphql_name 'AwardEmoji'
      description 'An emoji awarded by a user.'

      authorize :read_emoji

      present_using AwardEmojiPresenter

      field :name,
            GraphQL::STRING_TYPE,
            null: false,
            description: 'The emoji name'

      field :description,
            GraphQL::STRING_TYPE,
            null: false,
            description: 'The emoji description'

      field :unicode,
            GraphQL::STRING_TYPE,
            null: false,
            description: 'The emoji in unicode'

      field :emoji,
            GraphQL::STRING_TYPE,
            null: false,
            description: 'The emoji as an icon'

      field :unicode_version,
            GraphQL::STRING_TYPE,
            null: false,
            description: 'The unicode version for this emoji'

      field :user,
            Types::UserType,
            null: false,
            description: 'The user who awarded the emoji',
            resolve: -> (award_emoji, _args, _context) {
              Gitlab::Graphql::Loaders::BatchModelLoader.new(User, award_emoji.user_id).find
            }
    end
  end
end
