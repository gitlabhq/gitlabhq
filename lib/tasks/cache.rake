namespace :cache do
  namespace :clear do
    REDIS_CLEAR_BATCH_SIZE = 1000 # There seems to be no speedup when pushing beyond 1,000
    REDIS_SCAN_START_STOP = '0' # Magic value, see http://redis.io/commands/scan

    desc "GitLab | Clear redis cache"
    task redis: :environment do
      Gitlab::Redis.with do |redis|
        cursor = REDIS_SCAN_START_STOP
        loop do
          cursor, keys = redis.scan(
            cursor,
            match: "#{Gitlab::Redis::CACHE_NAMESPACE}*",
            count: REDIS_CLEAR_BATCH_SIZE
          )

          redis.del(*keys) if keys.any?

          break if cursor == REDIS_SCAN_START_STOP
        end
      end
    end

    desc "GitLab | Clear database cache (in the background)"
    task db: :environment do
      ClearDatabaseCacheWorker.perform_async
    end

    task all: [:db, :redis]
  end

  task clear: 'cache:clear:redis'
end
