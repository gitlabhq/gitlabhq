# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class WorkersConcurrency
        CACHE_EXPIRES_IN = 15.seconds
        LEASE_EXPIRES_IN = 5.seconds

        CACHE_KEY = [:concurrency_limit, :workers].join(':')
        LEASE_KEY = [:concurrency_limit, :lease].join(':')

        class << self
          def current_for(worker:, skip_cache: false)
            worker_class = worker.is_a?(Class) ? worker : worker.class
            worker_name = worker_class.name

            workers(skip_cache: skip_cache)[worker_name].to_i
          end

          def workers(skip_cache: false)
            return workers_uncached if skip_cache

            with_cache { workers_uncached }
          end

          private

          # To calculate the `tally` takes hundreds of Redis calls so we
          # really want to minimize the risk of concurrently recalculating the value.
          # This caches the data in Redis for 15s but the 5s lease ensures that some
          # process will recalculate the cache every 5s. The reason we don't just use a
          # 5s cache is because the high concurrency of execution of this code path
          # means that we're very likely to have many concurrent cache misses which means
          # many processes concurrently recalculating the same cached value.
          def with_cache
            Gitlab::Redis::Cache.with do |redis|
              key_set = redis.set(LEASE_KEY, 1, ex: LEASE_EXPIRES_IN, nx: true)

              break update_workers_cache(redis) { yield } if key_set

              tally = redis.get(CACHE_KEY)
              break Gitlab::Json.parse(tally) if tally

              update_workers_cache(redis) { yield }
            end
          end

          def update_workers_cache(redis)
            tally = yield
            redis.set(CACHE_KEY, tally.to_json, ex: CACHE_EXPIRES_IN)

            tally
          end

          def workers_uncached
            Gitlab::Redis::Queues.instances.values.flat_map do |instance| # rubocop:disable Cop/RedisQueueUsage -- iterating over instances is allowed as we pass the pool to Sidekiq
              Sidekiq::Client.via(instance.sidekiq_redis) do
                sidekiq_workers.map { |_process_id, _thread_id, work| ::Gitlab::Json.parse(work.payload)['class'] }
              end
            end.tally
          end

          def sidekiq_workers
            Sidekiq::Workers.new.each
          end
        end
      end
    end
  end
end
