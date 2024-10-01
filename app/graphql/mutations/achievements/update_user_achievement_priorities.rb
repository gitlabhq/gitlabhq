# frozen_string_literal: true

module Mutations
  module Achievements
    class UpdateUserAchievementPriorities < BaseMutation
      graphql_name 'UserAchievementPrioritiesUpdate'

      field :user_achievements,
        [::Types::Achievements::UserAchievementType],
        null: false,
        description: 'Updated user achievements.'

      argument :user_achievement_ids,
        [::Types::GlobalIDType[::Achievements::UserAchievement]],
        required: true,
        description: 'Global IDs of the user achievements being prioritized, ' \
          'ordered from highest to lowest priority.'

      def resolve(args)
        user_achievements = args.delete(:user_achievement_ids).map { |id| find_object(id) }

        user_achievements.each do |user_achievement|
          unless Ability.allowed?(current_user, :update_owned_user_achievement, user_achievement)
            raise_resource_not_available_error!
          end
        end

        result = ::Achievements::UpdateUserAchievementPrioritiesService.new(current_user, user_achievements).execute
        { user_achievements: result.payload, errors: result.errors }
      end

      def find_object(id)
        ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(id, expected_type: ::Achievements::UserAchievement))
      end
    end
  end
end
