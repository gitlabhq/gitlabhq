# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      include LooksAhead

      type ::Types::WorkItems::TypeType.connection_type, null: true

      argument :name,
        ::Types::IssueTypeEnum,
        description: "Filter work item types by the given name.",
        required: false

      argument :only_available,
        ::GraphQL::Types::Boolean,
        description: "When true, returns only the available work item types for the current user.",
        required: false,
        experiment: { milestone: "18.6" }

      def resolve_with_lookahead(name: nil, only_available: false)
        context.scoped_set!(:resource_parent, object)

        result = ::WorkItems::TypesFinder
          .new(container: object)
          .execute(name: name, only_available: only_available)

        result = result.then { |types| apply_lookahead(types) } unless result.is_a?(Array)

        result
      end

      private

      def preloads
        return {} if Feature.enabled?(:work_item_system_defined_type, :instance)

        {
          widget_definitions: :enabled_widget_definitions
        }
      end
    end
  end
end
