module Gitlab
  module Metrics
    module Samplers
      class UnicornSampler < BaseSampler
        def initialize(interval)
          super(interval)
        end

        def unicorn_active_connections
          @unicorn_active_connections ||= Gitlab::Metrics.gauge(:unicorn_active_connections, 'Unicorn active connections', {}, :max)
        end

        def unicorn_queued_connections
          @unicorn_queued_connections ||= Gitlab::Metrics.gauge(:unicorn_queued_connections, 'Unicorn queued connections', {}, :max)
        end

        def enabled?
          # Raindrops::Linux.tcp_listener_stats is only present on Linux
          unicorn_with_listeners? && Raindrops::Linux.respond_to?(:tcp_listener_stats)
        end

        def sample
          Raindrops::Linux.tcp_listener_stats(tcp_listeners).each do |addr, stats|
            unicorn_active_connections.set({ type: 'tcp', address: addr }, stats.active)
            unicorn_queued_connections.set({ type: 'tcp', address: addr }, stats.queued)
          end

          Raindrops::Linux.unix_listener_stats(unix_listeners).each do |addr, stats|
            unicorn_active_connections.set({ type: 'unix', address: addr }, stats.active)
            unicorn_queued_connections.set({ type: 'unix', address: addr }, stats.queued)
          end
        end

        private

        def tcp_listeners
          @tcp_listeners ||= Unicorn.listener_names.grep(%r{\A[^/]+:\d+\z})
        end

        def unix_listeners
          @unix_listeners ||= Unicorn.listener_names - tcp_listeners
        end

        def unicorn_with_listeners?
          defined?(Unicorn) && Unicorn.listener_names.any?
        end
      end
    end
  end
end
