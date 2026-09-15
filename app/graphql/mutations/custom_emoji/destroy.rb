# frozen_string_literal: true

module Mutations
  module CustomEmoji
    class Destroy < BaseMutation
      graphql_name 'DestroyCustomEmoji'

      authorize :delete_custom_emoji

      authorize_granular_token permissions: :delete_custom_emoji,
        boundary_argument: :id,
        boundary: :group,
        boundary_type: :group

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
          custom_emoji: custom_emoji,
          errors: []
        }
      end
    end
  end
end
