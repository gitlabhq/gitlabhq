# frozen_string_literal: true

module Resolvers
  module Achievements
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class UserAchievementsForUserResolver < UserAchievementsResolver
      def resolve_with_lookahead
        super.order_by_priority_asc
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
