# frozen_string_literal: true

module Gitlab
  module Search
    # This is an abstract class used for storing/searching recently viewed
    # items. The #type and #finder methods are the only ones needed to be
    # implemented by classes inheriting from this.
    class RecentItems
      ITEMS_LIMIT = 100 # How much history to remember from the user
      SEARCH_LIMIT = 5 # How many matching items to return from search
      EXPIRES_AFTER = 7.days

      attr_reader :user

      def initialize(user:, items_limit: ITEMS_LIMIT, expires_after: EXPIRES_AFTER)
        @user = user
        @items_limit = items_limit
        @expires_after = expires_after
      end

      def log_view(item)
        with_redis do |redis|
          redis.zadd(key, Time.now.to_f, item.id)
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
        finder.new(user, search: term, in: 'title', skip_full_text_search_project_condition: true)
          .execute
          .limit(SEARCH_LIMIT).without_order.id_in_ordered(latest_ids)
      end

      private

      def latest_ids
        with_redis do |redis|
          redis.zrevrange(key, 0, @items_limit - 1)
        end.map(&:to_i)
      end

      def with_redis(&blk)
        Gitlab::Redis::SharedState.with(&blk) # rubocop: disable CodeReuse/ActiveRecord
      end

      def key
        "recent_items:#{type.name.downcase}:#{user.id}"
      end

      def type
        raise NotImplementedError
      end

      def finder
        raise NotImplementedError
      end
    end
  end
end
