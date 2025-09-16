# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemResolver < Resolvers::BaseResolver
      type ::Types::WorkItemType, null: true

      argument :iid, GraphQL::Types::String, required: true, description: 'IID of the work item.'

      def self.recent_services_map
        @recent_services_map ||= {
          'issue' => ::Gitlab::Search::RecentIssues
        }
      end

      def ready?(**args)
        return false if resource_parent.is_a?(Group) && !resource_parent.licensed_feature_available?(:epics)

        super
      end

      def resolve(iid:)
        work_item = ::WorkItem.find_by_namespace_id_and_iid(resource_parent.id, iid)

        log_recent_view(work_item) if work_item && current_user

        work_item
      end

      private

      def log_recent_view(work_item)
        base_type = work_item.work_item_type.base_type

        return unless self.class.recent_services_map.key?(base_type)

        service_class = self.class.recent_services_map[base_type]
        return unless service_class

        service_class.new(user: current_user).log_view(work_item)
      end

      def resource_parent
        # The namespace could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the namespace to query for work items, so
        # make sure it's loaded and not `nil` before continuing.
        object.respond_to?(:sync) ? object.sync : object
      end
      strong_memoize_attr :resource_parent
    end
  end
end

Resolvers::Namespaces::WorkItemResolver.prepend_mod
