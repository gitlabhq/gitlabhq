# frozen_string_literal: true

module Mutations
  module Achievements
    class Award < BaseMutation
      graphql_name 'AchievementsAward'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :user_achievement,
        ::Types::Achievements::UserAchievementType,
        null: true,
        description: 'Achievement award.'

      argument :achievement_id, ::Types::GlobalIDType[::Achievements::Achievement],
        required: true,
        description: 'Global ID of the achievement being awarded.'

      argument :user_id, ::Types::GlobalIDType[::User],
        required: true,
        description: 'Global ID of the user being awarded the achievement.'

      argument :award_message, GraphQL::Types::String,
        required: false,
        validates: { length: { maximum: 200 } },
        description: 'Message to associate with the awarded achievement.'

      authorize :award_achievement

      def resolve(args)
        achievement = authorized_find!(id: args[:achievement_id])

        recipient_id = args[:user_id].model_id
        result = ::Achievements::AwardService.new(
          current_user, achievement.id, recipient_id, award_message: args[:award_message]
        ).execute
        { user_achievement: result.payload, errors: result.errors }
      end
    end
  end
end
