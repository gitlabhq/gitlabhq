# frozen_string_literal: true

module Resolvers
  module WorkItems
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class ChildrenResolver < HierarchyResolver
      argument :state, ::Types::WorkItemStateEnum,
        required: false,
        description: 'Current state of the child work items. Returns all states when omitted.'

      def resolve(state: nil)
        children = object.children(state: state)
        return WorkItem.none unless children.any?

        children = children.inc_relations_for_permission_check unless children.loaded?
        authorized_work_items(children)
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
