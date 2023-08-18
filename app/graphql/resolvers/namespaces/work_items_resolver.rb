# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemsResolver < BaseResolver
      prepend ::WorkItems::LookAheadPreloads

      type Types::WorkItemType.connection_type, null: true

      def resolve_with_lookahead(**args)
        return unless Feature.enabled?(:namespace_level_work_items, resource_parent)
        return WorkItem.none if resource_parent.nil?

        finder = ::WorkItems::NamespaceWorkItemsFinder.new(current_user, args.merge(
          namespace_id: resource_parent
        ))

        Gitlab::Graphql::Loaders::IssuableLoader.new(resource_parent, finder).batching_find_all do |q|
          apply_lookahead(q)
        end
      end

      private

      def resource_parent
        # The project could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the project to query for work items, so
        # make sure it's loaded and not `nil` before continuing.
        object.respond_to?(:sync) ? object.sync : object
      end
      strong_memoize_attr :resource_parent
    end
  end
end
