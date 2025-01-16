# frozen_string_literal: true

module Resolvers
  module WorkItems
    class AncestorsResolver < BaseResolver
      prepend ::WorkItems::LookAheadPreloads

      type ::Types::WorkItemType.connection_type, null: true

      def resolve_with_lookahead
        ancestors = object.ancestors
        return WorkItem.none unless ancestors

        truncate_ancestors(apply_lookahead(ancestors)).reverse!
      end

      private

      def truncate_ancestors(ancestors)
        # Iterate from closest ancestor until root or first missing ancestor
        authorized = authorized_ancestors(ancestors)

        previous_ancestor = object.work_item
        authorized.take_while do |ancestor|
          is_direct_parent = previous_ancestor.work_item_parent.id == ancestor.id
          previous_ancestor = ancestor

          is_direct_parent
        end
      end

      def authorized_ancestors(ancestors)
        preload_resource_parents(ancestors)

        DeclarativePolicy.user_scope do
          ancestors.select { |ancestor| Ability.allowed?(current_user, :read_work_item, ancestor) }
        end
      end

      def preload_resource_parents(work_items)
        return unless current_user

        projects = work_items.filter_map(&:project)
        namespaces = work_items.filter_map(&:namespace)
        group_namespaces = namespaces.select { |n| n.type == ::Group.sti_name }

        ::Preloaders::GroupPolicyPreloader.new(group_namespaces, current_user).execute if group_namespaces.any?
        return unless projects.any?

        ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute

        if group_namespaces.any?
          ::Preloaders::GroupPolicyPreloader.new(projects.filter_map(&:namespace), current_user).execute
        end

        ActiveRecord::Associations::Preloader.new(records: projects, associations: [:namespace]).call
      end

      def unconditional_includes
        [:namespace, :work_item_parent, ::Gitlab::Issues::TypeAssociationGetter.call]
      end
    end
  end
end
