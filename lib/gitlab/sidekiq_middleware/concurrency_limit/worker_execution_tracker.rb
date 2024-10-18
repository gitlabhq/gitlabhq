# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class WorkerExecutionTracker
        TRACKING_KEY_TTL = 600.seconds

        def initialize(worker_name:, prefix:)
          @worker_name = worker_name
          @prefix = prefix
        end

        def track_execution_start
          return if sidekiq_pid.nil?

          process_thread_id = process_thread_id_key(sidekiq_pid, sidekiq_tid)
          with_redis do |r|
            r.hset(worker_executing_hash_key, process_thread_id, Time.now.utc.tv_sec)
          end
        end

        def track_execution_end
          return if sidekiq_pid.nil?

          process_thread_id = process_thread_id_key(sidekiq_pid, sidekiq_tid)
          with_redis do |r|
            r.hdel(worker_executing_hash_key, process_thread_id)
          end
        end

        def cleanup_stale_trackers
          executing_threads_hash = with_redis { |r| r.hgetall(worker_executing_hash_key) }
          return if executing_threads_hash.empty?

          dangling = executing_threads_hash.filter { |k, v| !still_executing?(k, v) }
          return if dangling.empty?

          with_redis do |r|
            r.hdel(worker_executing_hash_key, dangling)
          end
        end

        def concurrent_worker_count
          with_redis { |r| r.hlen(worker_executing_hash_key).to_i }
        end

        private

        attr_reader :worker_name

        def with_redis(&)
          Redis::QueuesMetadata.with(&) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def worker_executing_hash_key
          "#{@prefix}:{#{worker_name.underscore}}:executing"
        end

        def process_thread_id_key(pid, tid)
          "#{pid}:tid:#{tid}"
        end

        def sidekiq_pid
          Gitlab::SidekiqProcess.pid
        end

        def sidekiq_tid
          Gitlab::SidekiqProcess.tid
        end

        def still_executing?(ptid, started_at)
          return true unless started_at.to_i < TRACKING_KEY_TTL.ago.utc.to_i

          pid, tid = ptid.split(":tid:")
          return false unless pid && tid

          job_hash = fetch_sidekiq_process_work_hash(pid, tid)
          return false if job_hash.empty?

          job_hash['class'] == worker_name
        end

        def fetch_sidekiq_process_work_hash(pid, tid)
          job_hash = {}
          Gitlab::SidekiqSharding::Router.route(worker_name.safe_constantize) do
            hash = Sidekiq.redis { |r| r.hget("#{pid}:work", tid) } # rubocop:disable Cop/SidekiqRedisCall -- checking process work hash
            next if hash.nil?

            # There are 2 layers of JSON encoding
            # 1. when a job is pushed into the queue -- https://github.com/sidekiq/sidekiq/blob/v7.2.4/lib/sidekiq/client.rb#L261
            # 2. When the workstate is written into the pid:work hash -- https://github.com/sidekiq/sidekiq/blob/v7.2.4/lib/sidekiq/launcher.rb#L148
            job_hash = ::Gitlab::Json.parse(::Gitlab::Json.parse(hash)&.dig('payload'))
          end

          job_hash
        rescue JSON::ParserError => e
          Gitlab::ErrorTracking.track_exception(e, worker_class: worker_name)
          {}
        end
      end
    end
  end
end
