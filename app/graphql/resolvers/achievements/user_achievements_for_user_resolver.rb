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
        super().then do |relation|
          next relation.shown_on_profile unless include_hidden && current_user

          # Profile owner sees all their own achievements
          next relation if current_user == object

          hidden_achievements_for_awarder(relation)
        end.order_by_priority_asc
      end

      private

      # Returns the union of publicly shown achievements and achievements hidden on profile
      # that the current_user is allowed to see as an awarder (maintainer or owner of the
      # achievement's namespace, via direct membership, inherited access, or group-link).
      # Uses Groups::AcceptingProjectImportsFinder, which implements the same three-path
      # namespace union used here.
      def hidden_achievements_for_awarder(relation)
        awarder_namespaces = ::Groups::AcceptingProjectImportsFinder.new(current_user).execute.select(:id)
        shown = relation.shown_on_profile
        awarder_relation = relation.for_namespaces(awarder_namespaces).hidden_on_profile
        ::Achievements::UserAchievement.from_union([shown, awarder_relation])
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
