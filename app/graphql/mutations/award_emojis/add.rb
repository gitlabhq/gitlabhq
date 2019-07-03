# frozen_string_literal: true

module Mutations
  module AwardEmojis
    class Add < Base
      graphql_name 'AddAwardEmoji'

      def resolve(args)
        awardable = authorized_find!(id: args[:awardable_id])

        check_object_is_awardable!(awardable)

        # TODO this will be handled by AwardEmoji::AddService
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/63372 and
        # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/29782
        award = awardable.create_award_emoji(args[:name], current_user)

        {
          award_emoji: (award if award.persisted?),
          errors: errors_on_object(award)
        }
      end
    end
  end
end
