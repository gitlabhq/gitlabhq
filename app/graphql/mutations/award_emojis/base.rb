# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Base < BaseMutation
      NOT_EMOJI_AWARDABLE = 'You cannot add emoji reactions to this resource.'

      authorize :award_emoji

      argument :awardable_id,
        ::Types::GlobalIDType[::Awardable],
        required: true,
        description: 'Global ID of the awardable resource.'

      argument :name,
        GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::AwardEmojis::AwardEmojiType, :name)

      field :award_emoji,
        Types::AwardEmojis::AwardEmojiType,
        null: true,
        description: 'Emoji reactions after mutation.'

      private

      def authorize!(object)
        super

        return unless !object.emoji_awardable? || cannot_read_merge_request?(object)

        raise_resource_not_available_error!(NOT_EMOJI_AWARDABLE)
      end

      def cannot_read_merge_request?(object)
        object.is_a?(MergeRequest) && !Ability.allowed?(current_user, :read_merge_request, object)
      end
    end
  end
end
