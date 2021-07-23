# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Base < BaseMutation
      include ::Mutations::FindsByGid

      NOT_EMOJI_AWARDABLE = 'You cannot award emoji to this resource.'

      authorize :award_emoji

      argument :awardable_id,
               ::Types::GlobalIDType[::Awardable],
               required: true,
               description: 'The global ID of the awardable resource.'

      argument :name,
               GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::AwardEmojis::AwardEmojiType, :name)

      field :award_emoji,
            Types::AwardEmojis::AwardEmojiType,
            null: true,
            description: 'The award emoji after mutation.'

      private

      # TODO: remove this method when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      def find_object(id:)
        super(id: ::Types::GlobalIDType[::Awardable].coerce_isolated_input(id))
      end

      def authorize!(object)
        super
        raise_resource_not_available_error!(NOT_EMOJI_AWARDABLE) unless object.emoji_awardable?
      end
    end
  end
end
