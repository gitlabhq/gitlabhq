# frozen_string_literal: true

module Mutations
  # rubocop:disable Gitlab/BoundedContexts -- the Achievements module already exists and holds the other mutations as well
  module Achievements
    class UpdateUserAchievement < BaseMutation
      graphql_name 'UserAchievementsUpdate'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :user_achievement,
        ::Types::Achievements::UserAchievementType,
        null: true,
        description: 'Achievement award.'

      argument :user_achievement_id,
        ::Types::GlobalIDType[::Achievements::UserAchievement],
        required: true,
        description: 'Global ID of the user achievement being updated.'

      argument :show_on_profile,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Indicates whether or not the user achievement is visible on the profile.'

      authorize :update_user_achievement

      def resolve(args)
        user_achievement = authorized_find!(id: args.delete(:user_achievement_id))

        result = ::Achievements::UpdateUserAchievementService.new(current_user, user_achievement, args).execute
        { user_achievement: result.payload, errors: result.errors }
      end

      def find_object(id:)
        GitlabSchema.object_from_id(id)
      end
    end
  end
  # rubocop:enable Gitlab/BoundedContexts
end
