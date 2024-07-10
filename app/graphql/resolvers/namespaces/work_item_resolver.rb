# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemResolver < Resolvers::BaseResolver
      type ::Types::WorkItemType, null: true

      argument :iid, GraphQL::Types::String, required: true, description: 'IID of the work item.'

      def ready?(**args)
        return false if resource_parent.is_a?(Group) && !resource_parent.namespace_work_items_enabled?

        super
      end

      def resolve(iid:)
        ::WorkItem.find_by_namespace_id_and_iid(resource_parent.id, iid)
      end

      private

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
