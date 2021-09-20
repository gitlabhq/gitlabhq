# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open issues of a group.
  class OpenIssuesCountService < Groups::CountService
    # TOTAL_COUNT_KEY includes confidential and hidden issues (admin)
    # TOTAL_COUNT_WITHOUT_HIDDEN_KEY includes confidential issues but not hidden issues (reporter and above)
    # PUBLIC_COUNT_WITHOUT_HIDDEN_KEY does not include confidential or hidden issues (guest)
    TOTAL_COUNT_KEY = 'group_open_issues_including_hidden_count'
    TOTAL_COUNT_WITHOUT_HIDDEN_KEY = 'group_open_issues_without_hidden_count'
    PUBLIC_COUNT_WITHOUT_HIDDEN_KEY = 'group_open_public_issues_without_hidden_count'

    def clear_all_cache_keys
      [cache_key(TOTAL_COUNT_KEY), cache_key(TOTAL_COUNT_WITHOUT_HIDDEN_KEY), cache_key(PUBLIC_COUNT_WITHOUT_HIDDEN_KEY)].each do |key|
        Rails.cache.delete(key)
      end
    end

    private

    def cache_key_name
      if include_hidden?
        TOTAL_COUNT_KEY
      elsif public_only?
        PUBLIC_COUNT_WITHOUT_HIDDEN_KEY
      else
        TOTAL_COUNT_WITHOUT_HIDDEN_KEY
      end
    end

    def include_hidden?
      strong_memoize(:user_is_admin) do
        user&.can_admin_all_resources?
      end
    end

    def public_only?
      !user_is_at_least_reporter?
    end

    def user_is_at_least_reporter?
      strong_memoize(:user_is_at_least_reporter) do
        group.member?(user, Gitlab::Access::REPORTER)
      end
    end

    def relation_for_count
      IssuesFinder.new(
        user,
        group_id: group.id,
        state: 'opened',
        non_archived: true,
        include_subgroups: true,
        public_only: public_only?,
        include_hidden: include_hidden?
      ).execute
    end

    def issuable_key
      'open_issues'
    end
  end
end
