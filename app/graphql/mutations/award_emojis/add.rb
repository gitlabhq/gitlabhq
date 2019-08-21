# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Add < Base
      graphql_name 'AddAwardEmoji'

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        check_object_is_awardable!(awardable)

        service = ::AwardEmojis::AddService.new(awardable, args[:name], current_user).execute

        {
          award_emoji: (service[:award] if service[:status] == :success),
          errors: service[:errors] || []
        }
      end
    end
  end
end
