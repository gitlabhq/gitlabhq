# frozen_string_literal: true

module Resolvers
  module Achievements
    class AchievementsResolver < BaseResolver
      include LooksAhead

      type ::Types::Achievements::AchievementType.connection_type, null: true

      argument :ids, [::Types::GlobalIDType[::Achievements::Achievement]],
        required: false,
        description: 'Filter achievements by IDs.'

      alias_method :namespace, :object

      def resolve_with_lookahead(**args)
        return ::Achievements::Achievement.none if Feature.disabled?(:achievements, namespace)

        params = {}
        params[:ids] = args[:ids].map(&:model_id) if args[:ids].present?

        achievements = ::Achievements::AchievementsFinder.new(namespace, params).execute
        apply_lookahead(achievements)
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
