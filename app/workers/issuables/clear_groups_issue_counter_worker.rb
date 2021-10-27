# frozen_string_literal: true

module Issuables
  class ClearGroupsIssueCounterWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!
    urgency :low
    feature_category :team_planning

    def perform(group_ids = [])
      return if group_ids.empty?

      groups_with_ancestors = Gitlab::ObjectHierarchy
        .new(Group.by_id(group_ids))
        .base_and_ancestors

      clear_cached_count(groups_with_ancestors)
    end

    private

    def clear_cached_count(groups)
      groups.each do |group|
        Groups::OpenIssuesCountService.new(group).clear_all_cache_keys
      end
    end
  end
end
