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
            .select { |job_klass| job_klass.to_s.safe_constantize.present? }
            .map { |job_klass| job_klass.safe_constantize.queue }
            .uniq

          job_klasses_queues.each do |queue|
            delete_jobs_for(
              set: Sidekiq::Queue.new(queue),
              job_klasses: job_klasses,
              kwargs: kwargs
            )
          end

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

        def sidekiq_queue_migrate(queue_from, to:)
          while sidekiq_queue_length(queue_from) > 0
            Sidekiq.redis do |conn|
              conn.rpoplpush "queue:#{queue_from}", "queue:#{to}"
            end
          end
        end

        def sidekiq_queue_length(queue_name)
          Sidekiq.redis do |conn|
            conn.llen("queue:#{queue_name}")
          end
        end

        private

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
