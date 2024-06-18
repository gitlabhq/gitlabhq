# frozen_string_literal: true

module Resolvers
  module Issues
    class BaseParentResolver < Issues::BaseResolver
      prepend ::Issues::LookAheadPreloads
      include ::Issues::SortArguments

      argument :state, Types::IssuableStateEnum,
        required: false,
        description: 'Current state of the issue.',
        prepare: ->(state, _ctx) {
          return state unless state == 'locked'

          raise Gitlab::Graphql::Errors::ArgumentError, Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE
        }

      type Types::IssueType.connection_type, null: true

      def resolve_with_lookahead(**args)
        return Issue.none if resource_parent.nil?

        finder = IssuesFinder.new(current_user, prepare_finder_params(args))

        issues = Gitlab::Graphql::Loaders::IssuableLoader.new(resource_parent, finder).batching_find_all do |q|
          apply_lookahead(q)
        end

        if non_stable_cursor_sort?(args[:sort])
          # Certain complex sorts are not supported by the stable cursor pagination yet.
          # In these cases, we use offset pagination, so we return the correct connection.
          offset_pagination(issues)
        else
          issues
        end
      end

      private

      def resource_parent
        # The project could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the project to query for issues, so
        # make sure it's loaded and not `nil` before continuing.
        strong_memoize(:resource_parent) do
          object.respond_to?(:sync) ? object.sync : object
        end
      end
    end
  end
end

Resolvers::Issues::BaseParentResolver.prepend_mod
