# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open issues of a group.
  class OpenIssuesCountService < Groups::CountService
    extend ::Gitlab::Utils::Override

    PUBLIC_COUNT_KEY = 'group_public_open_issues_count'
    TOTAL_COUNT_KEY = 'group_total_open_issues_count'

    override :initialize
    def initialize(*args, fast_timeout: false)
      super(*args)

      @fast_timeout = fast_timeout
    end

    def clear_all_cache_keys
      [cache_key(PUBLIC_COUNT_KEY), cache_key(TOTAL_COUNT_KEY)].each do |key|
        Rails.cache.delete(key)
      end
    end

    private

    override :uncached_count
    def uncached_count
      return super unless @fast_timeout

      ApplicationRecord.with_fast_read_statement_timeout do # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- this is called outside a transaction
        super
      end
    end

    def cache_key_name
      public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
    end

    def public_only?
      # Although PLANNER is not a linear access level, it can be considered so for the purpose of issues visibility
      # because the same permissions apply to all levels higher than Gitlab::Access::PLANNER
      !user_is_at_least_planner?
    end

    def user_is_at_least_planner?
      strong_memoize(:user_is_at_least_planner) do
        group.member?(user, Gitlab::Access::PLANNER)
      end
    end

    def relation_for_count
      confidential_filter = public_only? ? false : nil

      IssuesFinder.new(
        user,
        group_id: group.id,
        state: 'opened',
        non_archived: true,
        include_subgroups: true,
        confidential: confidential_filter
      ).execute
    end

    def issuable_key
      'open_issues'
    end
  end
end
