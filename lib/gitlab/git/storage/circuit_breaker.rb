module Gitlab
  module Git
    module Storage
      class CircuitBreaker
        attr_reader :storage,
                    :hostname,
                    :storage_path,
                    :failure_count_threshold,
                    :failure_wait_time,
                    :failure_reset_time,
                    :storage_timeout

        def self.reset_all!
          pattern = "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}*"

          Gitlab::Git::Storage.redis.with do |redis|
            all_storage_keys = redis.keys(pattern)
            redis.del(*all_storage_keys) unless all_storage_keys.empty?
          end

          RequestStore.delete(:circuitbreaker_cache)
        end

        def self.for_storage(storage)
          cached_circuitbreakers = RequestStore.fetch(:circuitbreaker_cache) do
            Hash.new do |hash, storage_name|
              hash[storage_name] = new(storage_name)
            end
          end

          cached_circuitbreakers[storage]
        end

        def initialize(storage, hostname = Gitlab::Environment.hostname)
          @storage = storage
          @hostname = hostname

          config = Gitlab.config.repositories.storages[@storage]
          @storage_path = config['path']
          @failure_count_threshold = config['failure_count_threshold']
          @failure_wait_time = config['failure_wait_time']
          @failure_reset_time = config['failure_reset_time']
          @storage_timeout = config['storage_timeout']
        end

        def perform
          return yield unless Feature.enabled?('git_storage_circuit_breaker')

          if circuit_broken?
            raise Gitlab::Git::Storage::CircuitOpen.new("Circuit for #{storage} open", failure_wait_time)
          end

          check_storage_accessible!

          yield
        end

        def circuit_broken?
          return false if no_failures?

          recent_failure = last_failure > failure_wait_time.seconds.ago
          too_many_failures = failure_count > failure_count_threshold

          recent_failure || too_many_failures
        end

        # Memoizing the `storage_available` call means we only do it once per
        # request when the storage is available.
        #
        # When the storage appears not available, and the memoized value is `false`
        # we might want to try again.
        def storage_available?
          @storage_available ||= Gitlab::Git::Storage::ForkedStorageCheck.storage_available?(storage_path, storage_timeout)
        end

        def check_storage_accessible!
          if storage_available?
            track_storage_accessible
          else
            track_storage_inaccessible
            raise Gitlab::Git::Storage::Inaccessible.new("#{storage} not accessible", failure_wait_time)
          end
        end

        def no_failures?
          last_failure.blank? && failure_count == 0
        end

        def track_storage_inaccessible
          @failure_info = [Time.now, failure_count + 1]

          Gitlab::Git::Storage.redis.with do |redis|
            redis.pipelined do
              redis.hset(cache_key, :last_failure, last_failure.to_i)
              redis.hincrby(cache_key, :failure_count, 1)
              redis.expire(cache_key, failure_reset_time)
            end
          end
        end

        def track_storage_accessible
          return if no_failures?

          @failure_info = [nil, 0]

          Gitlab::Git::Storage.redis.with do |redis|
            redis.pipelined do
              redis.hset(cache_key, :last_failure, nil)
              redis.hset(cache_key, :failure_count, 0)
            end
          end
        end

        def last_failure
          failure_info.first
        end

        def failure_count
          failure_info.last
        end

        def failure_info
          @failure_info ||= get_failure_info
        end

        def get_failure_info
          last_failure, failure_count = Gitlab::Git::Storage.redis.with do |redis|
            redis.hmget(cache_key, :last_failure, :failure_count)
          end

          last_failure = Time.at(last_failure.to_i) if last_failure.present?

          [last_failure, failure_count.to_i]
        end

        def cache_key
          @cache_key ||= "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}#{storage}:#{hostname}"
        end
      end
    end
  end
end
