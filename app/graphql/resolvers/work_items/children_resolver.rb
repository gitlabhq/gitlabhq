# frozen_string_literal: true

module Resolvers
  module WorkItems
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class ChildrenResolver < HierarchyResolver
      def resolve
        children = object.children
        return WorkItem.none unless children.any?

        children = children.inc_relations_for_permission_check unless children.loaded?
        authorized_work_items(children)
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
