# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open merge requests of a group.
  class MergeRequestsCountService < Groups::CountService
    private

    def cache_key_name
      'open_merge_requests_count'
    end

    def relation_for_count
      MergeRequestsFinder
      .new(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true)
      .execute
    end

    def issuable_key
      'open_merge_requests'
    end
  end
end
