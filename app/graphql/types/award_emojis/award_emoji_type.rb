# frozen_string_literal: true

module Types
  module AwardEmojis
    class AwardEmojiType < BaseObject
      graphql_name 'AwardEmoji'
      description 'An emoji awarded by a user'

      authorize :read_emoji

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      present_using AwardEmojiPresenter

      field :name,
        GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Emoji name.'

      field :description,
        GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Emoji description.'

      field :unicode,
        GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Emoji in Unicode.'

      field :emoji,
        GraphQL::Types::String,
        null: true,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Emoji as an icon.'

      field :unicode_version,
        GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Unicode version for the emoji.'

      field :user,
        Types::UserType,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'User who awarded the emoji.'

      def user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
      end
    end
  end
end
