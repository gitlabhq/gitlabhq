module Gitlab
  class UserActivities
    KEY = 'user/activities'
    DEFAULT_PAGE_SIZE = 50

    def self.record(user)
      Gitlab::Redis.with do |redis|
        redis.zadd(KEY, Time.now.to_i, user.username)
      end
    end

    def self.query(*args)
      new(*args).query
    end

    def initialize(from: 6.months.ago, page: 0, per_page: DEFAULT_PAGE_SIZE)
      @from = from
      @page = page
      @per_page = per_page
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
