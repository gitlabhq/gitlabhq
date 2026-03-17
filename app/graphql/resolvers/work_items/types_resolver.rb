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

      def resolve_with_lookahead(name: nil, only_available: false)
        context.scoped_set!(:resource_parent, object)

        ::WorkItems::TypesFinder
          .new(container: object)
          .execute(name: name, only_available: only_available)
      end
    end
  end
end
