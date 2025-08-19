# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemStateCountsResolver < WorkItemsResolver
      type Types::WorkItemStateCountsType, null: true

      def resolve(**args)
        return if resource_parent.nil?

        work_items_finder = finder(prepare_finder_params(args))
        work_items_finder.parent_param = resource_parent unless group_namespace?

        Gitlab::IssuablesCountForState.new(
          work_items_finder,
          resource_parent,
          # fast_fail and store_in_redis_cache only for group namespaces, to match behaviour of project level
          # WorkItemStateCountsResolver
          fast_fail: group_namespace?,
          store_in_redis_cache: group_namespace?
        )
      end
    end
  end
end
