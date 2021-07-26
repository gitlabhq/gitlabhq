# frozen_string_literal: true

module Types
  module AwardEmojis
    class AwardEmojiType < BaseObject
      graphql_name 'AwardEmoji'
      description 'An emoji awarded by a user'

      authorize :read_emoji

      present_using AwardEmojiPresenter

      field :name,
            GraphQL::Types::String,
            null: false,
            description: 'The emoji name.'

      field :description,
            GraphQL::Types::String,
            null: false,
            description: 'The emoji description.'

      field :unicode,
            GraphQL::Types::String,
            null: false,
            description: 'The emoji in Unicode.'

      field :emoji,
            GraphQL::Types::String,
            null: false,
            description: 'The emoji as an icon.'

      field :unicode_version,
            GraphQL::Types::String,
            null: false,
            description: 'The Unicode version for this emoji.'

      field :user,
            Types::UserType,
            null: false,
            description: 'The user who awarded the emoji.'

      def user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
      end
    end
  end
end
