# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      include LooksAhead

      type ::Types::WorkItems::TypeType.connection_type, null: true

      argument :name,
        ::Types::IssueTypeEnum,
        description: "Filter work item types by the given name.",
        required: false,
        deprecated: {
          reason: "Name-based filtering is no longer supported with introduction of " \
            "configurable work item types in 19.0",
          milestone: "19.0"
        }

      argument :only_available,
        ::GraphQL::Types::Boolean,
        description: "When true, returns only the available work item types for the current user. " \
          "This experimental field will be removed in 19.0. " \
          "Use canUserCreateItems and isFilterableListView fields from the WorkItemTypes API instead.",
        required: false,
        experiment: { milestone: "18.6" }

      def resolve_with_lookahead(**args)
        context.scoped_set!(:resource_parent, object)

        # Only forward `only_available` when the client actually provided it.
        # When omitted, the finder uses its `nil` sentinel default and returns
        # the generally-available types for the namespace (all types with
        # FF/license filters applied). Forwarding `false` here would instead
        # take the legacy "return everything unfiltered" branch.
        finder_args = { name: args[:name] }
        finder_args[:only_available] = args[:only_available] if args.key?(:only_available)

        ::WorkItems::TypesFinder
          .new(container: object)
          .execute(**finder_args)
      end
    end
  end
end
