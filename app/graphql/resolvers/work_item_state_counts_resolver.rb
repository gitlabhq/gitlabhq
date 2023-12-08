# frozen_string_literal: true

module Resolvers
  class WorkItemStateCountsResolver < WorkItemsResolver
    type Types::WorkItemStateCountsType, null: true

    def resolve(**args)
      return if resource_parent.nil?

      work_item_finder = finder(prepare_finder_params(args))
      work_item_finder.parent_param = resource_parent

      Gitlab::IssuablesCountForState.new(work_item_finder, resource_parent)
    end
  end
end
