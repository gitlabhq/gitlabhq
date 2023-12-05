# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      include LooksAhead

      type Types::WorkItems::TypeType.connection_type, null: true

      argument :taskable, ::GraphQL::Types::Boolean,
               required: false,
               description: 'If `true`, only taskable work item types will be returned.' \
                            ' Argument is experimental and can be removed in the future without notice.'

      def resolve_with_lookahead(taskable: nil)
        context.scoped_set!(:resource_parent, object)

        # This will require a finder in the future when groups/projects get their work item types
        # All groups/projects use the default types for now
        base_scope = ::WorkItems::Type.default
        base_scope = base_scope.by_type(:task) if taskable

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
          widget_definitions: { allowed_child_types: :allowed_child_types_by_name }
        }
      end
    end
  end
end
