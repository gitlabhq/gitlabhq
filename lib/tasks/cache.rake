namespace :cache do
  CLEAR_BATCH_SIZE = 1000 # There seems to be no speedup when pushing beyond 1,000
  REDIS_SCAN_START_STOP = '0' # Magic value, see http://redis.io/commands/scan

  desc "GitLab | Clear redis cache"
  task :clear => :environment do
    redis = Redis.new(url: Gitlab::RedisConfig.url)
    cursor = REDIS_SCAN_START_STOP
    loop do
      cursor, keys = redis.scan(
        cursor,
        match: "#{Gitlab::REDIS_CACHE_NAMESPACE}*", 
        count: CLEAR_BATCH_SIZE
      )

      redis.del(*keys) if keys.any?

      break if cursor == REDIS_SCAN_START_STOP
    end
  end
end
