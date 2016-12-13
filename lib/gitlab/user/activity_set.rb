module Gitlab
  module User
    class ActivitySet
      KEY = 'user/activities'
      DEFAULT_PAGE_SIZE = 50
      DEFAULT_FROM = 1.year.ago

      def self.record(user)
        Gitlab::Redis.with do |redis|
          redis.zadd(KEY, Time.now.to_i, user.username)
        end
      end

      def self.query(*args)
        new(*args).query
      end

      def initialize(from:, page:, per_page:)
        @from = from || DEFAULT_FROM
        @page = page || 0
        @per_page = per_page || DEFAULT_PAGE_SIZE
      end

      def query
        Gitlab::Redis.with do |redis|
          redis.zrangebyscore(KEY, @from.to_i, Time.now.to_i, with_scores: true, limit: [offset, @per_page])
        end
      end

      private

      def offset
        @page * @per_page
      end
    end
  end
end
