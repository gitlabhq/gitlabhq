# frozen_string_literal: true

module Resolvers
  module Achievements
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class UserAchievementsForUserResolver < UserAchievementsResolver
      argument :include_hidden,
        GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Indicates whether or not achievements hidden from the profile should be included in the result.'

      def resolve_with_lookahead(include_hidden:)
        relation = super().order_by_priority_asc

        if include_hidden && current_user == object
          relation
        else
          relation.shown_on_profile
        end
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
