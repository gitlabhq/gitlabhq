# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemStateCountsResolver < WorkItemsResolver
      type Types::WorkItemStateCountsType, null: true

      def resolve(**args)
        return if resource_parent.nil?

        work_items_finder = finder(prepare_finder_params(args))

        Gitlab::IssuablesCountForState.new(
          work_items_finder,
          resource_parent,
          fast_fail: true,
          store_in_redis_cache: true
        )
      end
    end
  end
end
