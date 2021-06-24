# frozen_string_literal: true

module Gitlab
  class SidekiqQueue
    include Gitlab::Utils::StrongMemoize

    NoMetadataError = Class.new(StandardError)
    InvalidQueueError = Class.new(StandardError)

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
          .slice(*Gitlab::ApplicationContext::KNOWN_KEYS)
          .transform_keys { |key| "meta.#{key}" }
          .compact

      raise NoMetadataError if job_search_metadata.empty?
      raise InvalidQueueError unless queue

      queue.each do |job|
        if timeout_exceeded?(start_time, timeout)
          completed = false
          break
        end

        next unless job_matches?(job, job_search_metadata)

        job.delete
        deleted_jobs += 1
      end

      {
        completed: completed,
        deleted_jobs: deleted_jobs,
        queue_size: queue.size
      }
    end

    private

    def queue
      strong_memoize(:queue) do
        # Sidekiq::Queue.new always returns a queue, even if it doesn't
        # exist.
        Sidekiq::Queue.all.find { |queue| queue.name == queue_name }
      end
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
