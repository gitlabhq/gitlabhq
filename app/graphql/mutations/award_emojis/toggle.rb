# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Toggle < Base
      graphql_name 'ToggleAwardEmoji'

      field :toggledOn,
            GraphQL::BOOLEAN_TYPE,
            null: false,
            description: 'True when the emoji was awarded, false when it was removed'

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        check_object_is_awardable!(awardable)

        # TODO this will be handled by AwardEmoji::ToggleService
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        award = awardable.toggle_award_emoji(args[:name], current_user)

        # Destroy returns a collection :(
        award = award.first if award.is_a?(Array)

        errors = errors_on_object(award)

        toggled_on = awardable.awarded_emoji?(args[:name], current_user)

        {
          # For consistency with the AwardEmojis::Remove mutation, only return
          # the AwardEmoji if it was created and not destroyed
          award_emoji: (award if toggled_on),
          errors: errors,
          toggled_on: toggled_on
        }
      end
    end
  end
end
