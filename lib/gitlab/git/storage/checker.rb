module Gitlab
  module Git
    module Storage
      class Checker
        include CircuitBreakerSettings

        attr_reader :storage_path, :storage, :hostname, :logger
        METRICS_MUTEX = Mutex.new
        STORAGE_TIMING_BUCKETS = [0.1, 0.15, 0.25, 0.33, 0.5, 1, 1.5, 2.5, 5, 10, 15].freeze

        def self.check_all(logger = Rails.logger)
          threads = Gitlab.config.repositories.storages.keys.map do |storage_name|
            Thread.new do
              Thread.current[:result] = new(storage_name, logger).check_with_lease
            end
          end

          threads.map do |thread|
            thread.join
            thread[:result]
          end
        end

        def self.check_histogram
          @check_histogram ||=
            METRICS_MUTEX.synchronize do
              @check_histogram || Gitlab::Metrics.histogram(:circuitbreaker_storage_check_duration_seconds,
                                                            'Storage check time in seconds',
                                                            {},
                                                            STORAGE_TIMING_BUCKETS
                                                           )
            end
        end

        def initialize(storage, logger = Rails.logger)
          @storage = storage
          config = Gitlab.config.repositories.storages[@storage]
          @storage_path = config.legacy_disk_path
          @logger = logger

          @hostname = Gitlab::Environment.hostname
        end

        def check_with_lease
          lease_key = "storage_check:#{cache_key}"
          lease = Gitlab::ExclusiveLease.new(lease_key, timeout: storage_timeout)
          result = { storage: storage, success: nil }

          if uuid = lease.try_obtain
            result[:success] = check

            Gitlab::ExclusiveLease.cancel(lease_key, uuid)
          else
            logger.warn("#{hostname}: #{storage}: Skipping check, previous check still running")
          end

          result
        end

        def check
          if perform_access_check
            track_storage_accessible
            true
          else
            track_storage_inaccessible
            logger.error("#{hostname}: #{storage}: Not accessible.")
            false
          end
        end

        private

        def perform_access_check
          start_time = Gitlab::Metrics::System.monotonic_time

          Gitlab::Git::Storage::ForkedStorageCheck.storage_available?(storage_path, storage_timeout, access_retries)
        ensure
          execution_time = Gitlab::Metrics::System.monotonic_time - start_time
          self.class.check_histogram.observe({ storage: storage }, execution_time)
        end

        def track_storage_inaccessible
          first_failure = current_failure_info.first_failure || Time.now
          last_failure = Time.now

          Gitlab::Git::Storage.redis.with do |redis|
            redis.pipelined do
              redis.hset(cache_key, :first_failure, first_failure.to_i)
              redis.hset(cache_key, :last_failure, last_failure.to_i)
              redis.hincrby(cache_key, :failure_count, 1)
              redis.expire(cache_key, failure_reset_time)
              maintain_known_keys(redis)
            end
          end
        end

        def track_storage_accessible
          Gitlab::Git::Storage.redis.with do |redis|
            redis.pipelined do
              redis.hset(cache_key, :first_failure, nil)
              redis.hset(cache_key, :last_failure, nil)
              redis.hset(cache_key, :failure_count, 0)
              maintain_known_keys(redis)
            end
          end
        end

        def maintain_known_keys(redis)
          expire_time = Time.now.to_i + failure_reset_time
          redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, expire_time, cache_key)
          redis.zremrangebyscore(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, '-inf', Time.now.to_i)
        end

        def current_failure_info
          FailureInfo.load(cache_key)
        end
      end
    end
  end
end
