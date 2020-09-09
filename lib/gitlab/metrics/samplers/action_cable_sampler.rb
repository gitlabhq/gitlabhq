# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ActionCableSampler < BaseSampler
        SAMPLING_INTERVAL_SECONDS = 5

        def metrics
          @metrics ||= {
            active_connections: ::Gitlab::Metrics.gauge(
              :action_cable_active_connections, 'Number of ActionCable WS clients currently connected'
            )
          }
        end

        def sample
          stats = sample_stats
          labels = {
            server_mode: server_mode
          }

          metrics[:active_connections].set(labels, stats[:active_connections])
        end

        private

        def sample_stats
          {
            active_connections: ::ActionCable.server.connections.size
          }
        end

        def server_mode
          Gitlab::ActionCable::Config.in_app? ? 'in-app' : 'standalone'
        end
      end
    end
  end
end
