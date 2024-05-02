# frozen_string_literal: true

module Mutations
  module CustomEmoji
    class Destroy < BaseMutation
      graphql_name 'DestroyCustomEmoji'

      authorize :delete_custom_emoji

      field :custom_emoji,
        Types::CustomEmojiType,
        null: true,
        description: 'Deleted custom emoji.'

      argument :id, ::Types::GlobalIDType[::CustomEmoji],
        required: true,
        description: 'Global ID of the custom emoji to destroy.'

      def resolve(id:)
        custom_emoji = authorized_find!(id: id)

        custom_emoji.destroy!

        {
          custom_emoji: custom_emoji
        }
      end
    end
  end
end
