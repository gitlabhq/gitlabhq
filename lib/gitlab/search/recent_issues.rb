# frozen_string_literal: true

module Gitlab
  module Search
    class RecentIssues
      ITEMS_LIMIT = 100
      EXPIRES_AFTER = 7.days

      def initialize(user:, items_limit: ITEMS_LIMIT, expires_after: EXPIRES_AFTER)
        @user = user
        @items_limit = items_limit
        @expires_after = expires_after
      end

      def log_view(issue)
        return unless recent_items_enabled?

        with_redis do |redis|
          redis.zadd(key, Time.now.to_f, issue.id)
          redis.expire(key, @expires_after)

          # There is a race condition here where we could end up removing an
          # item from 2 places concurrently but this is fine since worst case
          # scenario we remove an extra item from the end of the list.
          if redis.zcard(key) > @items_limit
            redis.zremrangebyrank(key, 0, 0) # Remove least recent
          end
        end
      end

      def search(term)
        return Issue.none unless recent_items_enabled?

        ids = with_redis do |redis|
          redis.zrevrange(key, 0, @items_limit - 1)
        end.map(&:to_i)

        IssuesFinder.new(@user, search: term, in: 'title').execute.reorder(nil).id_in_ordered(ids) # rubocop: disable CodeReuse/ActiveRecord
      end

      private

      def with_redis(&blk)
        Gitlab::Redis::SharedState.with(&blk) # rubocop: disable CodeReuse/ActiveRecord
      end

      def key
        "recent_items:#{type.name.downcase}:#{@user.id}"
      end

      def type
        Issue
      end

      def recent_items_enabled?
        Feature.enabled?(:recent_items_search, @user)
      end
    end
  end
end
