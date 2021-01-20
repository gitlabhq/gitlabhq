# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ActionCableSampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 5

        def initialize(interval = nil, action_cable: ::ActionCable.server)
          super(interval)
          @action_cable = action_cable
        end

        def metrics
          @metrics ||= {
            active_connections: ::Gitlab::Metrics.gauge(
              :action_cable_active_connections, 'Number of ActionCable WS clients currently connected'
            ),
            pool_min_size: ::Gitlab::Metrics.gauge(
              :action_cable_pool_min_size, 'Minimum number of worker threads in ActionCable thread pool'
            ),
            pool_max_size: ::Gitlab::Metrics.gauge(
              :action_cable_pool_max_size, 'Maximum number of worker threads in ActionCable thread pool'
            ),
            pool_current_size: ::Gitlab::Metrics.gauge(
              :action_cable_pool_current_size, 'Current number of worker threads in ActionCable thread pool'
            ),
            pool_largest_size: ::Gitlab::Metrics.gauge(
              :action_cable_pool_largest_size, 'Largest number of worker threads observed so far in ActionCable thread pool'
            ),
            pool_completed_tasks: ::Gitlab::Metrics.gauge(
              :action_cable_pool_tasks_total, 'Total number of tasks executed in ActionCable thread pool'
            ),
            pool_pending_tasks: ::Gitlab::Metrics.gauge(
              :action_cable_pool_pending_tasks, 'Number of tasks waiting to be executed in ActionCable thread pool'
            )
          }
        end

        def sample
          pool = @action_cable.worker_pool.executor
          labels = {
            server_mode: server_mode
          }

          metrics[:active_connections].set(labels, @action_cable.connections.size)
          metrics[:pool_min_size].set(labels, pool.min_length)
          metrics[:pool_max_size].set(labels, pool.max_length)
          metrics[:pool_current_size].set(labels, pool.length)
          metrics[:pool_largest_size].set(labels, pool.largest_length)
          metrics[:pool_completed_tasks].set(labels, pool.completed_task_count)
          metrics[:pool_pending_tasks].set(labels, pool.queue_length)
        end

        private

        def server_mode
          Gitlab::ActionCable::Config.in_app? ? 'in-app' : 'standalone'
        end
      end
    end
  end
end
