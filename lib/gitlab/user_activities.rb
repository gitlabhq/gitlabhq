module Gitlab
  class UserActivities
    include Enumerable

    KEY = 'users:activities'.freeze
    BATCH_SIZE = 500

    def self.record(key, time = Time.now)
      Gitlab::Redis::SharedState.with do |redis|
        redis.hset(KEY, key, time.to_i)
      end
    end

    def delete(*keys)
      Gitlab::Redis::SharedState.with do |redis|
        redis.hdel(KEY, keys)
      end
    end

    def each
      cursor = 0
      loop do
        cursor, pairs =
          Gitlab::Redis::SharedState.with do |redis|
            redis.hscan(KEY, cursor, count: BATCH_SIZE)
          end

        Hash[pairs].each { |pair| yield pair }

        break if cursor == '0'
      end
    end
  end
end
