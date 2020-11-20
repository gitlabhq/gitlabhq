# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Remove < Base
      graphql_name 'AwardEmojiRemove'

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        service = ::AwardEmojis::DestroyService.new(awardable, args[:name], current_user).execute

        {
          # Mutation response is always a `nil` award_emoji
          errors: service[:errors] || []
        }
      end
    end
  end
end
