# frozen_string_literal: true

module Resolvers
  module Achievements
    class UserAchievementsResolver < BaseResolver
      include LooksAhead

      type ::Types::Achievements::UserAchievementType.connection_type, null: true

      def resolve_with_lookahead
        user_achievements = object.user_achievements.not_revoked.order_by_id_asc

        apply_lookahead(user_achievements)
      end

      private

      def unconditional_includes
        [
          { achievement: [:namespace] }
        ]
      end

      def preloads
        {
          user: [:user],
          awarded_by_user: [:awarded_by_user],
          revoked_by_user: [:revoked_by_user]
        }
      end
    end
  end
end
