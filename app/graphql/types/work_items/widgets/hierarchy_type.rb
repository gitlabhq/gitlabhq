# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class HierarchyType < BaseObject
        graphql_name 'WorkItemWidgetHierarchy'
        description 'Represents a hierarchy widget'

        implements ::Types::WorkItems::WidgetInterface

        field :parent, ::Types::WorkItemType,
          null: true, complexity: 5,
          description: 'Parent work item.'

        field :children, ::Types::WorkItemType.connection_type,
          null: true, complexity: 5,
          description: 'Child work items.'

        field :ancestors, ::Types::WorkItemType.connection_type,
          null: true, complexity: 5,
          description: 'Ancestors (parents) of the work item.',
          extras: [:lookahead],
          resolver: Resolvers::WorkItems::AncestorsResolver

        field :has_children, GraphQL::Types::Boolean,
          null: false, description: 'Indicates if the work item has children.'

        field :has_parent, GraphQL::Types::Boolean,
          null: false, method: :has_parent?, description: 'Indicates if the work item has a parent.'

        field :rolled_up_counts_by_type, [::Types::WorkItems::WorkItemTypeCountsByStateType],
          null: false, description: 'Counts of descendant work items by work item type and state.',
          experiment: { milestone: '17.3' }

        field :depth_limit_reached_by_type, [::Types::WorkItems::WorkItemTypeDepthLimitReachedByType],
          null: false, description: 'Depth limit reached by allowed work item type.',
          experiment: { milestone: '17.4' }

        # rubocop: disable CodeReuse/ActiveRecord
        def has_children?
          BatchLoader::GraphQL.for(object.work_item.id).batch(default_value: false) do |ids, loader|
            links_for_parents = ::WorkItems::ParentLink.for_parents(ids)
                                           .select(:work_item_parent_id)
                                           .group(:work_item_parent_id)
                                           .reorder(nil)

            links_for_parents.each { |link| loader.call(link.work_item_parent_id, true) }
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        alias_method :has_children, :has_children?

        def children
          relation = object.children
          relation = relation.inc_relations_for_permission_check unless object.children.loaded?

          relation
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
