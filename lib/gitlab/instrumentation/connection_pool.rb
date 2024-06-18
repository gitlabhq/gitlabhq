# frozen_string_literal: true

module Gitlab
  module Instrumentation
    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- this module patches ConnectionPool to instrument it
    module ConnectionPool
      def initialize(options = {}, &block)
        @name = options.fetch(:name, 'unknown')

        super
      end

      def checkout(options = {})
        conn = super

        connection_class = conn.class.to_s
        track_available_connections(connection_class)
        track_pool_size(connection_class)

        conn
      end

      def track_pool_size(connection_class)
        # this means that the size metric for this pool key has been sent
        return if @size_gauge

        @size_gauge ||= ::Gitlab::Metrics.gauge(:gitlab_connection_pool_size, 'Size of connection pool', {}, :all)
        @size_gauge.set({ pool_name: @name, connection_class: connection_class }, @size)
      end

      def track_available_connections(connection_class)
        @available_gauge ||= ::Gitlab::Metrics.gauge(:gitlab_connection_pool_available_count,
          'Number of available connections in the pool', {}, :all)

        @available_gauge.set({ pool_name: @name, connection_class: connection_class }, available)
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
