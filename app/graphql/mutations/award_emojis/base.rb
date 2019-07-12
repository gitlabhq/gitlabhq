# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Base < BaseMutation
      authorize :award_emoji

      argument :awardable_id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the awardable resource'

      argument :name,
               GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::AwardEmojis::AwardEmojiType, :name)

      field :award_emoji,
            Types::AwardEmojis::AwardEmojiType,
            null: true,
            description: 'The award emoji after mutation'

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end

      # Called by mutations methods after performing an authorization check
      # of an awardable object.
      def check_object_is_awardable!(object)
        unless object.is_a?(Awardable) && object.emoji_awardable?
          raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                'Cannot award emoji to this resource'
        end
      end
    end
  end
end
