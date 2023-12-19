# frozen_string_literal: true

module Mutations
  module Achievements
    class DeleteUserAchievement < BaseMutation
      graphql_name 'UserAchievementsDelete'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :user_achievement,
        ::Types::Achievements::UserAchievementType,
        null: true,
        description: 'Deleted user achievement.'

      argument :user_achievement_id, ::Types::GlobalIDType[::Achievements::UserAchievement],
        required: true,
        description: 'Global ID of the user achievement being deleted.'

      authorize :destroy_user_achievement

      def resolve(args)
        user_achievement = authorized_find!(id: args[:user_achievement_id])

        result = ::Achievements::DestroyUserAchievementService.new(current_user, user_achievement).execute
        { user_achievement: result.payload, errors: result.errors }
      end
    end
  end
end
