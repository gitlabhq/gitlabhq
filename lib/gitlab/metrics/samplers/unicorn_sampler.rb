# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class UnicornSampler < BaseSampler
        def metrics
          @metrics ||= init_metrics
        end

        def init_metrics
          {
            unicorn_active_connections: ::Gitlab::Metrics.gauge(:unicorn_active_connections, 'Unicorn active connections', {}, :max),
            unicorn_queued_connections: ::Gitlab::Metrics.gauge(:unicorn_queued_connections, 'Unicorn queued connections', {}, :max),
            unicorn_workers:            ::Gitlab::Metrics.gauge(:unicorn_workers, 'Unicorn workers')
          }
        end

        def enabled?
          # Raindrops::Linux.tcp_listener_stats is only present on Linux
          unicorn_with_listeners? && Raindrops::Linux.respond_to?(:tcp_listener_stats)
        end

        def sample
          Raindrops::Linux.tcp_listener_stats(tcp_listeners).each do |addr, stats|
            set_unicorn_connection_metrics('tcp', addr, stats)
          end
          Raindrops::Linux.unix_listener_stats(unix_listeners).each do |addr, stats|
            set_unicorn_connection_metrics('unix', addr, stats)
          end

          metrics[:unicorn_workers].set({}, unicorn_workers_count)
        end

        private

        def tcp_listeners
          @tcp_listeners ||= Unicorn.listener_names.grep(%r{\A[^/]+:\d+\z})
        end

        def set_unicorn_connection_metrics(type, addr, stats)
          labels = { socket_type: type, socket_address: addr }

          metrics[:unicorn_active_connections].set(labels, stats.active)
          metrics[:unicorn_queued_connections].set(labels, stats.queued)
        end

        def unix_listeners
          @unix_listeners ||= Unicorn.listener_names - tcp_listeners
        end

        def unicorn_with_listeners?
          defined?(Unicorn) && Unicorn.listener_names.any?
        end

        def unicorn_workers_count
          http_servers.sum(&:worker_processes) # rubocop: disable CodeReuse/ActiveRecord
        end

        # Traversal of ObjectSpace is expensive, on fully loaded application
        # it takes around 80ms. The instances of HttpServers are not a subject
        # to change so we can cache the list of servers.
        def http_servers
          return [] unless defined?(::Unicorn::HttpServer)

          @http_servers ||= ObjectSpace.each_object(::Unicorn::HttpServer).to_a
        end
      end
    end
  end
end
