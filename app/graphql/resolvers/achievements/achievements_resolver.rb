# frozen_string_literal: true

module Resolvers
  module Achievements
    class AchievementsResolver < BaseResolver
      include LooksAhead

      type ::Types::Achievements::AchievementType.connection_type, null: true

      alias_method :namespace, :object

      def resolve_with_lookahead
        return ::Achievements::Achievement.none if Feature.disabled?(:achievements, namespace)

        apply_lookahead(namespace.achievements)
      end

      private

      def preloads
        {
          user_achievements: [{ user_achievements: [:user, :awarded_by_user, :revoked_by_user] }]
        }
      end
    end
  end
end
