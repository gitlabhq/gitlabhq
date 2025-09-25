# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemStateCountsResolver < WorkItemsResolver
      type Types::WorkItemStateCountsType, null: true

      def resolve(**args)
        return if resource_parent.nil?

        work_items_finder = finder(prepare_finder_params(args))
        work_items_finder.parent_param = resource_parent unless group_namespace?

        # For the group issues list, we don't want the use the reduced query timeout, since the counts for the list
        # can take some time to return. By contrast, the group epics list counts are cached, and can use the reduced
        # timeout. We use the exclude_group_work_items param to differentiate the 2 queries.
        is_group_issues_list = args[:exclude_group_work_items]

        Gitlab::IssuablesCountForState.new(
          work_items_finder,
          resource_parent,
          # fast_fail and store_in_redis_cache only for group namespaces, to match behaviour of project level
          # WorkItemStateCountsResolver.
          fast_fail: group_namespace? && !is_group_issues_list,
          store_in_redis_cache: group_namespace?
        )
      end
    end
  end
end
