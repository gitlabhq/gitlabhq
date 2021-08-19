# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Toggle < Base
      graphql_name 'AwardEmojiToggle'

      field :toggled_on, GraphQL::Types::Boolean, null: false,
            description: 'Indicates the status of the emoji. ' \
            'True if the toggle awarded the emoji, and false if the toggle removed the emoji.'

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        service = ::AwardEmojis::ToggleService.new(awardable, args[:name], current_user).execute

        toggled_on = awardable.awarded_emoji?(args[:name], current_user)

        {
          # For consistency with the AwardEmojis::Remove mutation, only return
          # the AwardEmoji if it was created and not destroyed
          award_emoji: (service[:award] if toggled_on),
          errors: service[:errors] || [],
          toggled_on: toggled_on
        }
      end
    end
  end
end
