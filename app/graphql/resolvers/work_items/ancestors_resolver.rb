# frozen_string_literal: true

module Resolvers
  module WorkItems
    # rubocop:disable Graphql/ResolverType -- the type is inherited from the parent class
    class AncestorsResolver < HierarchyResolver
      prepend ::WorkItems::LookAheadPreloads

      def resolve_with_lookahead
        ancestors = object.ancestors
        return WorkItem.none unless ancestors

        truncate_ancestors(apply_lookahead(ancestors)).reverse!
      end

      private

      def truncate_ancestors(ancestors)
        # Iterate from the closest ancestor until root or first missing ancestor
        authorized = authorized_work_items(ancestors)

        previous_ancestor = object.work_item
        authorized.take_while do |ancestor|
          is_direct_parent = previous_ancestor.work_item_parent.id == ancestor.id
          previous_ancestor = ancestor

          is_direct_parent
        end
      end

      def unconditional_includes
        [:namespace, :work_item_parent, :work_item_type]
      end
    end
    # rubocop:enable Graphql/ResolverType
  end
end
