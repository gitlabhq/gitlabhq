# frozen_string_literal: true

module Gitlab
  class SidekiqQueue
    include Gitlab::Utils::StrongMemoize

    NoMetadataError = Class.new(StandardError)
    InvalidQueueError = Class.new(StandardError)

    WORKER_KEY = 'worker_class'
    ALLOWED_KEYS = Gitlab::ApplicationContext.allowed_job_keys.map(&:to_s) + [WORKER_KEY]

    attr_reader :queue_name

    def initialize(queue_name)
      @queue_name = queue_name
    end

    def drop_jobs!(search_metadata, timeout:)
      start_time = monotonic_time
      completed = true
      deleted_jobs = 0

      job_search_metadata =
        search_metadata
          .stringify_keys
          .slice(*ALLOWED_KEYS)
          .transform_keys(&method(:transform_key))
          .compact

      raise NoMetadataError if job_search_metadata.empty?
      raise InvalidQueueError if sidekiq_queues.values.compact.empty?

      Gitlab::Redis::Queues.instances.map do |key, instance|
        queue = sidekiq_queues[key]
        next if queue.nil?

        Sidekiq::Client.via(instance.sidekiq_redis) do
          queue.each do |job|
            if timeout_exceeded?(start_time, timeout)
              completed = false
              break
            end

            next unless job_matches?(job, job_search_metadata)

            job.delete
            deleted_jobs += 1
          end
        end
      end

      {
        completed: completed,
        deleted_jobs: deleted_jobs,
        queue_size: queue_size
      }
    end

    private

    def transform_key(key)
      if Gitlab::ApplicationContext.known_keys.include?(key.to_sym)
        "meta.#{key}"
      elsif key == WORKER_KEY
        'class'
      end
    end

    def sidekiq_queues
      @sidekiq_queues ||= Gitlab::Redis::Queues.instances.to_h do |name, instance|
        Sidekiq::Client.via(instance.sidekiq_redis) do
          [name, Sidekiq::Queue.all.find { |queue| queue.name == queue_name }]
        end
      end
    end

    def queue_size
      sidekiq_queues.filter_map do |k, v|
        instance = Gitlab::Redis::Queues.instances[k]
        next if instance.nil?

        # .size calls `llen` using Sidekiq.redis, hence we need to wrap it with .via
        Sidekiq::Client.via(instance.sidekiq_redis) { v.size }
      end.sum
    end

    def job_matches?(job, job_search_metadata)
      job_search_metadata.all? { |key, value| job[key] == value }
    end

    def timeout_exceeded?(start_time, timeout)
      (monotonic_time - start_time) > timeout
    end

    def monotonic_time
      Gitlab::Metrics::System.monotonic_time
    end
  end
end
