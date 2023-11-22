# frozen_string_literal: true

module Mutations
  module Achievements
    class Delete < BaseMutation
      graphql_name 'AchievementsDelete'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      field :achievement,
        ::Types::Achievements::AchievementType,
        null: true,
        description: 'Achievement.'

      argument :achievement_id, ::Types::GlobalIDType[::Achievements::Achievement],
        required: true,
        description: 'Global ID of the achievement being deleted.'

      authorize :admin_achievement

      def resolve(args)
        achievement = authorized_find!(id: args[:achievement_id])

        result = ::Achievements::DestroyService.new(current_user, achievement).execute
        { achievement: result.payload, errors: result.errors }
      end
    end
  end
end
