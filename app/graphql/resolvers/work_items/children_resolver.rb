# frozen_string_literal: true

module Resolvers
  module WorkItems
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class ChildrenResolver < HierarchyResolver
      prepend ::WorkItems::LookAheadPreloads

      argument :state, ::Types::WorkItemStateEnum,
        required: false,
        description: 'Current state of the child work items. Returns all states when omitted.'

      def resolve_with_lookahead(state: nil)
        children = object.children(state: state)
        return WorkItem.none unless children.any?

        children = apply_lookahead(children) unless children.loaded?
        authorized_work_items(children)
      end

      def unconditional_includes
        [
          {
            project: { namespace: :route },
            namespace: { parent: :route }
          },
          *super
        ]
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
