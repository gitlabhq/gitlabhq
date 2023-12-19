# frozen_string_literal: true

module Resolvers
  module Namespaces
    class WorkItemStateCountsResolver < WorkItemsResolver
      type Types::WorkItemStateCountsType, null: true

      def ready?(**args)
        # The search filter is not supported for work times at the namespace level.
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/393126
        if args[:search]
          raise Gitlab::Graphql::Errors::ArgumentError,
            'Searching is not available for work items at the namespace level yet'
        end

        super
      end

      def resolve(**args)
        return if resource_parent.nil?

        Gitlab::IssuablesCountForState.new(
          finder(args),
          resource_parent,
          store_in_redis_cache: true
        )
      end
    end
  end
end
