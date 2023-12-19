# frozen_string_literal: true

module Mutations
  module Achievements
    class Update < BaseMutation
      graphql_name 'AchievementsUpdate'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :achievement,
        ::Types::Achievements::AchievementType,
        null: true,
        description: 'Achievement.'

      argument :achievement_id, ::Types::GlobalIDType[::Achievements::Achievement],
        required: true,
        description: 'Global ID of the achievement being updated.'

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Name for the achievement.'

      argument :avatar, ApolloUploadServer::Upload,
        required: false,
        description: 'Avatar for the achievement.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description of or notes for the achievement.'

      authorize :admin_achievement

      def resolve(args)
        achievement = authorized_find!(id: args[:achievement_id])

        args.delete(:achievement_id)
        result = ::Achievements::UpdateService.new(current_user, achievement, args).execute
        { achievement: result.payload, errors: result.errors }
      end
    end
  end
end
