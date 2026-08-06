# frozen_string_literal: true

module Resolvers
  class IssuesResolver < Issues::BaseResolver
    prepend ::Issues::LookAheadPreloads
    include ::Issues::SortArguments
    include ::Issuables::RootArguments

    argument :include_archived, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Whether to include issues from archived projects. Defaults to `false`.'
    argument :state, Types::IssuableStateEnum,
      required: false,
      description: 'Current state of the issue.',
      prepare: ->(state, _ctx) {
        return state unless state == 'locked'

        raise Gitlab::Graphql::Errors::ArgumentError, Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE
      }

    type Types::IssueType.connection_type, null: true

    before_connection_authorization do |nodes, current_user|
      ::Preloaders::IssuablesPreloader.new(nodes, current_user, project_associations).preload_all
    end

    def self.project_associations
      [:namespace, :organization]
    end

    def resolve_with_lookahead(**args)
      issues = apply_lookahead(
        IssuesFinder.new(current_user, prepare_finder_params(args)).execute
      )

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        offset_pagination(issues)
      else
        issues
      end
    end
  end
end

Resolvers::IssuesResolver.prepend_mod
