# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Add < Base
      graphql_name 'AwardEmojiAdd'

      authorize_granular_token permissions: :create_award_emoji,
        boundaries: [
          { boundary_argument: :awardable_id, boundary: :resource_parent, boundary_type: :project },
          { boundary_argument: :awardable_id, boundary: :resource_parent, boundary_type: :group }
        ]

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        service = ::AwardEmojis::AddService.new(awardable, args[:name], current_user).execute

        {
          award_emoji: (service[:award] if service[:status] == :success),
          errors: service[:errors] || []
        }
      end
    end
  end
end
