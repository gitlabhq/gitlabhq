# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      include LooksAhead

      type ::Types::WorkItems::TypeType.connection_type, null: true

      argument :name, ::Types::IssueTypeEnum,
        description: 'Filter work item types by the given name.',
        required: false

      def resolve_with_lookahead(name: nil)
        context.scoped_set!(:resource_parent, object)

        # This will require a finder in the future when groups/projects get their work item types
        # All groups/projects use all types for now
        base_scope = ::WorkItems::Type
        base_scope = base_scope.by_type(name) if name

        apply_lookahead(base_scope.order_by_name_asc)
      end

      private

      def preloads
        {
          widget_definitions: :enabled_widget_definitions
        }
      end

      def nested_preloads
        {
          widget_definitions: { allowed_child_types: :allowed_child_types_by_name,
                                allowed_parent_types: :allowed_parent_types_by_name }
        }
      end
    end
  end
end
