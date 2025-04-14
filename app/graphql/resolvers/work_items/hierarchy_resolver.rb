# frozen_string_literal: true

module Resolvers
  module WorkItems
    class HierarchyResolver < BaseResolver
      type Types::WorkItemType.connection_type, null: true

      private

      def authorized_work_items(work_items)
        preload_resource_parents(work_items) unless work_items.loaded?

        DeclarativePolicy.user_scope do
          work_items.select { |work_item| Ability.allowed?(current_user, :read_work_item, work_item) }
        end
      end

      def preload_resource_parents(work_items)
        return unless current_user

        projects = work_items.filter_map(&:project)
        ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute if projects.any?

        namespaces = work_items.map(&:namespace)
        namespaces_from_projects = projects.map(&:namespace)
        group_namespaces = (namespaces + namespaces_from_projects).select { |n| n.type == ::Group.sti_name }

        ::Preloaders::GroupPolicyPreloader.new(group_namespaces, current_user).execute
      end
    end
  end
end
