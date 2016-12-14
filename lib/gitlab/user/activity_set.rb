module Gitlab
  module User
    class ActivitySet
      include Gitlab::PaginationUtil

      KEY = 'user/activities'
      DEFAULT_FROM = 6.months.ago.to_i

      def self.record(user)
        Gitlab::Redis.with do |redis|
          redis.zadd(KEY, Time.now.to_i, user.username)
        end
      end

      def initialize(from:, page:, per_page:)
        @from = sanitize_date(from)
        @to = Time.now.to_i
        @page = page
        @per_page = per_page
      end

      def activities
        @activities ||= raw_activities.map { |activity| Activity.new(*activity) }
      end

      private

      def sanitize_date(date)
        Time.strptime(date, "%Y-%m-%d").to_i
      rescue TypeError, ArgumentError
        DEFAULT_FROM
      end

      def pagination_delegate
        @pagination_delegate ||= Gitlab::PaginationDelegate.new(page: @page,
                                                                per_page: @per_page,
                                                                count: count)
      end

      def raw_activities
        Gitlab::Redis.with do |redis|
          redis.zrangebyscore(KEY, @from, @to, with_scores: true, limit: limit)
        end
      end

      def count
        Gitlab::Redis.with do |redis|
          redis.zcount(KEY, @from, @to)
        end
      end

      def limit
        [pagination_delegate.offset, pagination_delegate.limit_value]
      end
    end
  end
end
