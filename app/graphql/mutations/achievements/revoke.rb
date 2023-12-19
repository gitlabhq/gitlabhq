# frozen_string_literal: true

module Mutations
  module Achievements
    class Revoke < BaseMutation
      graphql_name 'AchievementsRevoke'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :user_achievement,
        ::Types::Achievements::UserAchievementType,
        null: true,
        description: 'Achievement award.'

      argument :user_achievement_id, ::Types::GlobalIDType[::Achievements::UserAchievement],
        required: true,
        description: 'Global ID of the user achievement being revoked.'

      authorize :award_achievement

      def resolve(args)
        user_achievement = authorized_find!(id: args[:user_achievement_id])

        result = ::Achievements::RevokeService.new(current_user, user_achievement).execute
        { user_achievement: result.payload, errors: result.errors }
      end
    end
  end
end
