# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class ExclusiveLock
      MIGRATION_LEASE_KEY = 'click_house:migrations'
      MIGRATION_RETRY_DELAY = ->(num) { 0.2.seconds * (num**2) }
      MIGRATION_LOCK_DURATION = 1.hour

      ACTIVE_WORKERS_REDIS_KEY = 'click_house:workers:active_workers'
      DEFAULT_CLICKHOUSE_WORKER_TTL = 30.minutes
      WORKERS_WAIT_SLEEP = 5.seconds

      class << self
        include ::Gitlab::ExclusiveLeaseHelpers

        def register_running_worker(worker_class, worker_id)
          ttl = worker_class.click_house_worker_attrs[:migration_lock_ttl].from_now.utc

          Gitlab::Redis::SharedState.with do |redis|
            current_score = redis.zscore(ACTIVE_WORKERS_REDIS_KEY, worker_id).to_i

            if ttl.to_i > current_score
              # DO NOT send 'gt: true' parameter to avoid compatibility
              # problems with Redis versions older than 6.2.
              redis.zadd(ACTIVE_WORKERS_REDIS_KEY, ttl.to_i, worker_id)
            end

            yield
          ensure
            redis.zrem(ACTIVE_WORKERS_REDIS_KEY, worker_id)
          end
        end

        def execute_migration
          in_lock(MIGRATION_LEASE_KEY, ttl: MIGRATION_LOCK_DURATION, retries: 5, sleep_sec: MIGRATION_RETRY_DELAY) do
            wait_until_workers_inactive(DEFAULT_CLICKHOUSE_WORKER_TTL.from_now)

            yield
          end
        rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError => e
          raise ClickHouse::MigrationSupport::Errors::LockError, e.message
        end

        def pause_workers?
          Gitlab::ExclusiveLease.new(MIGRATION_LEASE_KEY, timeout: 0).exists?
        end

        def active_sidekiq_workers?
          Gitlab::Redis::SharedState.with do |redis|
            min = Time.now.utc.to_i

            # expire keys in the past
            redis.zremrangebyscore(ACTIVE_WORKERS_REDIS_KEY, 0, "(#{min}")
            # Return if any workers are registered with a future expiry date
            #
            # To be compatible with Redis 6.0 not use zrange with 'by_score: true' parameter
            # instead use redis.zrangebyscore method.
            redis.zrangebyscore(ACTIVE_WORKERS_REDIS_KEY, min, '+inf', limit: [0, 1]).any?
          end
        end

        def wait_until_workers_inactive(worker_wait_ttl)
          # Wait until the collection in ClickHouseWorker::CLICKHOUSE_ACTIVE_WORKERS_KEY is empty,
          # before continuing migration.
          workers_active = true

          loop do
            workers_active = active_sidekiq_workers?
            break unless workers_active
            break if Time.current >= worker_wait_ttl

            sleep WORKERS_WAIT_SLEEP.to_i
          end

          return unless workers_active

          raise ClickHouse::MigrationSupport::Errors::LockError, 'Timed out waiting for active workers'
        end
      end

      private_class_method :wait_until_workers_inactive
    end
  end
end
