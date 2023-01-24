# frozen_string_literal: true

module Resolvers
  class IssuesResolver < Issues::BaseResolver
    prepend ::Issues::LookAheadPreloads
    include ::Issues::SortArguments

    NON_FILTER_ARGUMENTS = %i[sort lookahead].freeze

    argument :state, Types::IssuableStateEnum,
              required: false,
              description: 'Current state of this issue.'

    # see app/graphql/types/issue_connection.rb
    type 'Types::IssueConnection', null: true

    before_connection_authorization do |nodes, current_user|
      projects = nodes.map(&:project)
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
    end

    def ready?(**args)
      unless filter_provided?(args)
        raise Gitlab::Graphql::Errors::ArgumentError, _('You must provide at least one filter argument for this query')
      end

      super
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

    private

    def filter_provided?(args)
      args.except(*NON_FILTER_ARGUMENTS).values.any?(&:present?)
    end
  end
end
