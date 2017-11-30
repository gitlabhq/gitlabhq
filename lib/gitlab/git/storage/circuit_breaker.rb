module Gitlab
  module Git
    module Storage
      class CircuitBreaker
        include CircuitBreakerSettings

        FailureInfo = Struct.new(:last_failure, :failure_count)

        attr_reader :storage,
                    :hostname,
                    :storage_path

        delegate :last_failure, :failure_count, to: :failure_info

        def self.reset_all!
          pattern = "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}*"

          Gitlab::Git::Storage.redis.with do |redis|
            all_storage_keys = redis.scan_each(match: pattern).to_a
            redis.del(*all_storage_keys) unless all_storage_keys.empty?
          end

          RequestStore.delete(:circuitbreaker_cache)
        end

        def self.for_storage(storage)
          cached_circuitbreakers = RequestStore.fetch(:circuitbreaker_cache) do
            Hash.new do |hash, storage_name|
              hash[storage_name] = build(storage_name)
            end
          end

          cached_circuitbreakers[storage]
        end

        def self.build(storage, hostname = Gitlab::Environment.hostname)
          config = Gitlab.config.repositories.storages[storage]

          if !config.present?
            NullCircuitBreaker.new(storage, hostname, error: Misconfiguration.new("Storage '#{storage}' is not configured"))
          elsif !config['path'].present?
            NullCircuitBreaker.new(storage, hostname, error: Misconfiguration.new("Path for storage '#{storage}' is not configured"))
          else
            new(storage, hostname)
          end
        end

        def initialize(storage, hostname)
          @storage = storage
          @hostname = hostname

          config = Gitlab.config.repositories.storages[@storage]
          @storage_path = config['path']
        end

        def perform
          return yield unless enabled?

          check_storage_accessible!

          yield
        end

        def circuit_broken?
          return false if no_failures?

          failure_count > failure_count_threshold
        end

        def backing_off?
          return false if no_failures?

          recent_failure = last_failure > failure_wait_time.seconds.ago
          too_many_failures = failure_count > backoff_threshold

          recent_failure && too_many_failures
        end

        private

        # The circuitbreaker can be enabled for the entire fleet using a Feature
        # flag.
        #
        # Enabling it for a single host can be done setting the
        # `GIT_STORAGE_CIRCUIT_BREAKER` environment variable.
        def enabled?
          ENV['GIT_STORAGE_CIRCUIT_BREAKER'].present? || Feature.enabled?('git_storage_circuit_breaker')
        end

        def failure_info
          @failure_info ||= get_failure_info
        end

        # Memoizing the `storage_available` call means we only do it once per
        # request when the storage is available.
        #
        # When the storage appears not available, and the memoized value is `false`
        # we might want to try again.
        def storage_available?
          return @storage_available if @storage_available

          if @storage_available = Gitlab::Git::Storage::ForkedStorageCheck
                                    .storage_available?(storage_path, storage_timeout, access_retries)
            track_storage_accessible
          else
            track_storage_inaccessible
          end

          @storage_available
        end

        def check_storage_accessible!
          if circuit_broken?
            raise Gitlab::Git::Storage::CircuitOpen.new("Circuit for #{storage} is broken", failure_reset_time)
          end

          if backing_off?
            raise Gitlab::Git::Storage::Failing.new("Backing off access to #{storage}", failure_wait_time)
          end

          unless storage_available?
            raise Gitlab::Git::Storage::Inaccessible.new("#{storage} not accessible", failure_wait_time)
          end
        end

        def no_failures?
          last_failure.blank? && failure_count == 0
        end

        def track_storage_inaccessible
          @failure_info = FailureInfo.new(Time.now, failure_count + 1)

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

          @failure_info = FailureInfo.new(nil, 0)

          Gitlab::Git::Storage.redis.with do |redis|
            redis.pipelined do
              redis.hset(cache_key, :last_failure, nil)
              redis.hset(cache_key, :failure_count, 0)
            end
          end
        end

        def get_failure_info
          last_failure, failure_count = Gitlab::Git::Storage.redis.with do |redis|
            redis.hmget(cache_key, :last_failure, :failure_count)
          end

          last_failure = Time.at(last_failure.to_i) if last_failure.present?

          FailureInfo.new(last_failure, failure_count.to_i)
        end

        def cache_key
          @cache_key ||= "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}#{storage}:#{hostname}"
        end
      end
    end
  end
end
