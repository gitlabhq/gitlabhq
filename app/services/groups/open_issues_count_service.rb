# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open issues of a group.
  class OpenIssuesCountService < BaseCountService
    include Gitlab::Utils::StrongMemoize

    VERSION = 1
    PUBLIC_COUNT_KEY = 'group_public_open_issues_count'
    TOTAL_COUNT_KEY = 'group_total_open_issues_count'
    CACHED_COUNT_THRESHOLD = 1000
    EXPIRATION_TIME = 24.hours

    attr_reader :group, :user

    def initialize(group, user = nil)
      @group = group
      @user = user
    end

    # Reads count value from cache and return it if present.
    # If empty or expired, #uncached_count will calculate the issues count for the group and
    # compare it with the threshold. If it is greater, it will be written to the cache and returned.
    # If below, it will be returned without being cached.
    # This results in only caching large counts and calculating the rest with every call to maintain
    # accuracy.
    def count
      cached_count = Rails.cache.read(cache_key)
      return cached_count unless cached_count.blank?

      refreshed_count = uncached_count
      update_cache_for_key(cache_key) { refreshed_count } if refreshed_count > CACHED_COUNT_THRESHOLD
      refreshed_count
    end

    def cache_key(key = nil)
      ['groups', 'open_issues_count_service', VERSION, group.id, cache_key_name]
    end

    private

    def cache_options
      super.merge({ expires_in: EXPIRATION_TIME })
    end

    def cache_key_name
      public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
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
      IssuesFinder.new(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true, public_only: public_only?).execute
    end
  end
end
