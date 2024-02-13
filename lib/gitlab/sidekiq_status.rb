# frozen_string_literal: true

module Gitlab
  # The SidekiqStatus module and its child classes can be used for checking if a
  # Sidekiq job has been processed or not.
  #
  # To check if a job has been completed, simply pass the job ID to the
  # `completed?` method:
  #
  #     job_id = SomeWorker.with_status.perform_async(...)
  #
  #     if Gitlab::SidekiqStatus.completed?(job_id)
  #       ...
  #     end
  #
  # If you do not use `with_status`, and the worker class does not declare
  # `status_expiration` in its `sidekiq_options`, then this status will not be
  # stored.
  #
  # For each job ID registered a separate key is stored in Redis, making lookups
  # much faster than using Sidekiq's built-in job finding/status API. These keys
  # expire after a certain period of time to prevent storing too many keys in
  # Redis.
  module SidekiqStatus
    STATUS_KEY = 'gitlab-sidekiq-status:%s'

    # The default time (in seconds) after which a status key is expired
    # automatically. The default of 30 minutes should be more than sufficient
    # for most jobs.
    DEFAULT_EXPIRATION = 30.minutes.to_i

    # Starts tracking of the given job.
    #
    # jid - The Sidekiq job ID
    # expire - The expiration time of the Redis key.
    def self.set(jid, expire = DEFAULT_EXPIRATION)
      return unless expire

      with_redis do |redis|
        redis.set(key_for(jid), 1, ex: expire.to_i)
      end
    end

    # Stops the tracking of the given job.
    #
    # jid - The Sidekiq job ID to remove.
    def self.unset(jid)
      with_redis do |redis|
        redis.del(key_for(jid))
      end
    end

    # Refreshes the timeout on the key if it exists
    #
    # jid = The Sidekiq job ID
    # expire - The expiration time of the Redis key.
    def self.expire(jid, expire = DEFAULT_EXPIRATION)
      with_redis do |redis|
        redis.expire(key_for(jid), expire.to_i)
      end
    end

    # Returns true if all the given job have been completed.
    #
    # job_ids - The Sidekiq job IDs to check.
    #
    # Returns true or false.
    def self.all_completed?(job_ids)
      self.num_running(job_ids) == 0
    end

    # Returns true if the given job is running or enqueued.
    #
    # job_id - The Sidekiq job ID to check.
    def self.running?(job_id)
      num_running([job_id]) > 0
    end

    # Returns the number of jobs that are running or enqueued.
    #
    # job_ids - The Sidekiq job IDs to check.
    def self.num_running(job_ids)
      responses = self.job_status(job_ids)

      responses.count(&:present?)
    end

    # Returns the number of jobs that have completed.
    #
    # job_ids - The Sidekiq job IDs to check.
    def self.num_completed(job_ids)
      job_ids.size - self.num_running(job_ids)
    end

    # Returns the job status for each of the given job IDs.
    #
    # job_ids - The Sidekiq job IDs to check.
    #
    # Returns an array of true or false indicating job completion.
    # true = job is still running or enqueued
    # false = job completed
    def self.job_status(job_ids)
      return [] if job_ids.empty?

      keys = job_ids.map { |jid| key_for(jid) }

      status = with_redis do |redis|
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          if Gitlab::Redis::ClusterUtil.cluster?(redis)
            Gitlab::Redis::ClusterUtil.batch_get(keys, redis)
          else
            redis.mget(*keys)
          end
        end
      end

      status.map { |result| !result.nil? }
    end

    # Returns the JIDs that are completed
    #
    # job_ids - The Sidekiq job IDs to check.
    #
    # Returns an array of completed JIDs
    def self.completed_jids(job_ids)
      statuses = job_status(job_ids)

      completed = []
      job_ids.zip(statuses).each do |job_id, status|
        completed << job_id unless status
      end

      completed
    end

    def self.key_for(jid)
      STATUS_KEY % jid
    end

    def self.with_redis
      Redis::QueuesMetadata.with { |redis| yield redis }
    end
    private_class_method :with_redis
  end
end
