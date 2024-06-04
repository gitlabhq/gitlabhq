# frozen_string_literal: true

module Resolvers
  class IssuesResolver < Issues::BaseResolver
    extend ::Gitlab::Utils::Override
    prepend ::Issues::LookAheadPreloads
    include ::Issues::SortArguments

    NON_FILTER_ARGUMENTS = %i[sort lookahead include_archived].freeze

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
      projects = nodes.map(&:project)
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
      ::Preloaders::GroupPolicyPreloader.new(projects.filter_map(&:group), current_user).execute
      ActiveRecord::Associations::Preloader.new(records: projects, associations: project_associations).call
    end

    def self.project_associations
      [:namespace]
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

    override :prepare_finder_params
    def prepare_finder_params(args)
      super.tap do |prepared|
        prepared[:non_archived] = !prepared.delete(:include_archived)
      end
    end

    def filter_provided?(args)
      args.except(*NON_FILTER_ARGUMENTS).values.any?(&:present?)
    end
  end
end

Resolvers::IssuesResolver.prepend_mod
