module Gitlab
  module UserActivities
    class ActivitySet
      delegate :total_count,
               :total_pages,
               :current_page,
               :limit_value,
               :first_page?,
               :prev_page,
               :last_page?,
               :next_page, to: :pagination_delegate

      KEY = 'user/activities'.freeze

      def self.record(user)
        Gitlab::Redis.with do |redis|
          redis.zadd(KEY, Time.now.to_i, user.username)
        end
      end

      def initialize(from: nil, page: nil, per_page: nil)
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
        default_from
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

      def default_from
        6.months.ago.to_i
      end
    end
  end
end
