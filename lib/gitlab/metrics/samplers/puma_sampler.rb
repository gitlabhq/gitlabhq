# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class PumaSampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 5

        def metrics
          @metrics ||= init_metrics
        end

        def init_metrics
          {
            puma_workers: ::Gitlab::Metrics.gauge(:puma_workers, 'Total number of workers'),
            puma_running_workers: ::Gitlab::Metrics.gauge(:puma_running_workers, 'Number of active workers'),
            puma_stale_workers: ::Gitlab::Metrics.gauge(:puma_stale_workers, 'Number of stale workers'),
            puma_running: ::Gitlab::Metrics.gauge(:puma_running, 'Number of running threads'),
            puma_queued_connections: ::Gitlab::Metrics.gauge(:puma_queued_connections, 'Number of connections in that worker\'s "todo" set waiting for a worker thread'),
            puma_active_connections: ::Gitlab::Metrics.gauge(:puma_active_connections, 'Number of threads processing a request'),
            puma_pool_capacity: ::Gitlab::Metrics.gauge(:puma_pool_capacity, 'Number of requests the worker is capable of taking right now'),
            puma_max_threads: ::Gitlab::Metrics.gauge(:puma_max_threads, 'Maximum number of worker threads'),
            puma_idle_threads: ::Gitlab::Metrics.gauge(:puma_idle_threads, 'Number of spawned threads which are not processing a request')
          }
        end

        def sample
          json_stats = puma_stats
          return unless json_stats

          stats = ::Gitlab::Json.parse(json_stats)

          if cluster?(stats)
            sample_cluster(stats)
          else
            sample_single_worker(stats)
          end
        end

        private

        def puma_stats
          ::Puma.stats
        rescue NoMethodError
          Gitlab::AppLogger.info "PumaSampler: stats are not available yet, waiting for Puma to boot"
          nil
        end

        def sample_cluster(stats)
          set_master_metrics(stats)

          stats['worker_status'].each do |worker|
            last_status = worker['last_status']
            labels = { worker: "worker_#{worker['index']}" }

            set_worker_metrics(last_status, labels) if last_status.present?
          end
        end

        def sample_single_worker(stats)
          metrics[:puma_workers].set({}, 1)
          metrics[:puma_running_workers].set({}, 1)

          set_worker_metrics(stats)
        end

        def cluster?(stats)
          stats['worker_status'].present?
        end

        def set_master_metrics(stats)
          labels = { worker: "master" }

          metrics[:puma_workers].set(labels, stats['workers'])
          metrics[:puma_running_workers].set(labels, stats['booted_workers'])
          metrics[:puma_stale_workers].set(labels, stats['old_workers'])
        end

        def set_worker_metrics(stats, labels = {})
          metrics[:puma_running].set(labels, stats['running'])
          metrics[:puma_queued_connections].set(labels, stats['backlog'])
          metrics[:puma_active_connections].set(labels, stats['max_threads'] - stats['pool_capacity'])
          metrics[:puma_pool_capacity].set(labels, stats['pool_capacity'])
          metrics[:puma_max_threads].set(labels, stats['max_threads'])
          metrics[:puma_idle_threads].set(labels, stats['running'] + stats['pool_capacity'] - stats['max_threads'])
        end
      end
    end
  end
end
