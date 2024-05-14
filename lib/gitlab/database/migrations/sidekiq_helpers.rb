# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      # rubocop:disable Cop/SidekiqApiUsage
      # rubocop:disable Cop/SidekiqRedisCall
      module SidekiqHelpers
        # Constants for default sidekiq_remove_jobs values
        DEFAULT_MAX_ATTEMPTS = 5
        DEFAULT_TIMES_IN_A_ROW = 2

        # Probabilistically removes job_klasses from their specific queues, the
        # retry set and the scheduled set.
        #
        # If jobs are still being processed at the same time, then there is a
        # small chance it will not remove all instances of job_klass. To
        # minimize this risk, it repeatedly removes matching jobs from each
        # until nothing is removed twice in a row.
        #
        # Before calling this method, you should make sure that job_klass is no
        # longer being scheduled within the running application.
        def sidekiq_remove_jobs(
          job_klasses:,
          times_in_a_row: DEFAULT_TIMES_IN_A_ROW,
          max_attempts: DEFAULT_MAX_ATTEMPTS
        )
          kwargs = { times_in_a_row: times_in_a_row, max_attempts: max_attempts }

          if transaction_open?
            raise 'sidekiq_remove_jobs can not be run inside a transaction, ' \
                  'you can disable transactions by calling disable_ddl_transaction! ' \
                  'in the body of your migration class'
          end

          job_klasses_queues = job_klasses
            .map { |job_klass| job_klass.to_s.safe_constantize }
            .select(&:present?)
            .map { |job_klass| [job_klass.queue, job_klass.get_sidekiq_options['store']] }
            .uniq

          job_klasses_queues.each do |queue, store|
            _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store)
            Sidekiq::Client.via(pool) do
              delete_jobs_for(
                set: Sidekiq::Queue.new(queue),
                job_klasses: job_klasses,
                kwargs: kwargs
              )
            end
          end

          results = job_klasses_queues.map(&:last).uniq.map do |store|
            _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store)
            Sidekiq::Client.via(pool) do
              delete_jobs_for(
                set: Sidekiq::RetrySet.new,
                kwargs: kwargs,
                job_klasses: job_klasses
              )

              delete_jobs_for(
                set: Sidekiq::ScheduledSet.new,
                kwargs: kwargs,
                job_klasses: job_klasses
              )
            end
          end

          aggregate_results(results)
        end

        def sidekiq_queue_migrate(queue_from, to:)
          src_stores = Gitlab::SidekiqConfig::WorkerRouter.global.stores_with_queue(queue_from)
          dst_stores = Gitlab::SidekiqConfig::WorkerRouter.global.stores_with_queue(to)

          if migrate_within_instance?(src_stores, dst_stores) || !Gitlab::SidekiqSharding::Router.enabled?
            migrate_within_instance(queue_from, to)
          else
            src_stores = [nil] if src_stores.empty? # route from main shard if empty
            dst_stores = [nil] if dst_stores.empty? # route to main shard if empty

            src_stores.each do |src_store|
              migrate_across_instance(queue_from, to, src_store, dst_stores)
            end
          end
        end

        # cross instance transfers are not atomic and data loss is possible
        def migrate_across_instance(queue_from, to, src_store, dst_stores)
          _, src_pool = Gitlab::SidekiqSharding::Router.get_shard_instance(src_store)
          buffer_queue_name = "migration_buffer:queue:#{queue_from}"

          while Sidekiq::Client.via(src_pool) { sidekiq_queue_length(queue_from) } > 0
            job = Sidekiq::Client.via(src_pool) do
              Sidekiq.redis do |c|
                c.rpoplpush("queue:#{queue_from}", buffer_queue_name)
              end
            end
            job_hash = Sidekiq.load_json(job)

            # In the case of multiple stores having the same queue name, we look up the store which the particular job
            # would have been enqueued to if `.perform_async` were called.
            dst_store_name = Gitlab::SidekiqConfig::WorkerRouter.global.store(job_hash["class"].safe_constantize)

            # Send the job to the first shard that contains the queue. This assumes that the queue has a listener
            # on that particular Redis instance. This only affects configurations which use multiple shards per queue.
            store_name = dst_stores.find { |ds| dst_store_name == ds } || dst_stores.first
            _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store_name)
            Sidekiq::Client.via(pool) { Sidekiq.redis { |c| c.lpush("queue:#{to}", job) } }
          end

          Sidekiq::Client.via(src_pool) { Sidekiq.redis { |c| c.unlink(buffer_queue_name) } }
        end

        def migrate_within_instance(queue_from, to)
          Sidekiq.redis do |conn|
            conn.rpoplpush "queue:#{queue_from}", "queue:#{to}" while sidekiq_queue_length(queue_from) > 0
          end
        end

        private

        def aggregate_results(results)
          { attempts: 0, success: false }.tap do |h|
            results.each do |result|
              h[:attempts] += result[:attempts]
              h[:success] |= result[:success]
            end
          end
        end

        def migrate_within_instance?(src_stores, dst_stores)
          (src_stores.empty? && dst_stores.empty?) ||
            (src_stores.size == 1 && dst_stores.size == 1 && src_stores.first == dst_stores.first)
        end

        def sidekiq_queue_length(queue_name)
          Sidekiq.redis do |conn|
            conn.llen("queue:#{queue_name}")
          end
        end

        # Handle the "jobs deleted" tracking that is needed in order to track
        # whether a job was deleted or not.
        def delete_jobs_for(set:, kwargs:, job_klasses:)
          until_equal_to(0, **kwargs) do
            set.count do |job|
              job_klasses.include?(job.klass) && job.delete
            end
          end
        end

        # Control how many times in a row you want to see a job deleted 0
        # times. The idea is that if you see 0 jobs deleted x number of times
        # in a row you've *likely* covered the case in which the queue was
        # mutating while this was running.
        def until_equal_to(target, times_in_a_row:, max_attempts:)
          streak = 0

          result = { attempts: 0, success: false }

          1.upto(max_attempts) do |current_attempt|
            # yield's return value is a count of "jobs_deleted"
            if yield == target
              streak += 1
            elsif streak > 0
              streak = 0
            end

            result[:attempts] = current_attempt
            result[:success] = streak == times_in_a_row

            break if result[:success]
          end
          result
        end
      end
      # rubocop:enable Cop/SidekiqApiUsage
      # rubocop:enable Cop/SidekiqRedisCall
    end
  end
end
