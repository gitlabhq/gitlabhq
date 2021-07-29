# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # The exceptions raised for connection errors.
      CONNECTION_ERRORS = if defined?(PG)
                            [
                              PG::ConnectionBad,
                              PG::ConnectionDoesNotExist,
                              PG::ConnectionException,
                              PG::ConnectionFailure,
                              PG::UnableToSend,
                              # During a failover this error may be raised when
                              # writing to a primary.
                              PG::ReadOnlySqlTransaction
                            ].freeze
                          else
                            [].freeze
                          end

      ProxyNotConfiguredError = Class.new(StandardError)

      # The connection proxy to use for load balancing (if enabled).
      def self.proxy
        unless @proxy
          Gitlab::ErrorTracking.track_exception(
            ProxyNotConfiguredError.new(
              "Attempting to access the database load balancing proxy, but it wasn't configured.\n" \
              "Did you forget to call '#{self.name}.configure_proxy'?"
            ))
        end

        @proxy
      end

      # Returns a Hash containing the load balancing configuration.
      def self.configuration
        Gitlab::Database.main.config[:load_balancing] || {}
      end

      # Returns the maximum replica lag size in bytes.
      def self.max_replication_difference
        (configuration['max_replication_difference'] || 8.megabytes).to_i
      end

      # Returns the maximum lag time for a replica.
      def self.max_replication_lag_time
        (configuration['max_replication_lag_time'] || 60.0).to_f
      end

      # Returns the interval (in seconds) to use for checking the status of a
      # replica.
      def self.replica_check_interval
        (configuration['replica_check_interval'] || 60).to_f
      end

      # Returns the additional hosts to use for load balancing.
      def self.hosts
        configuration['hosts'] || []
      end

      def self.service_discovery_enabled?
        configuration.dig('discover', 'record').present?
      end

      def self.service_discovery_configuration
        conf = configuration['discover'] || {}

        {
          nameserver: conf['nameserver'] || 'localhost',
          port: conf['port'] || 8600,
          record: conf['record'],
          record_type: conf['record_type'] || 'A',
          interval: conf['interval'] || 60,
          disconnect_timeout: conf['disconnect_timeout'] || 120,
          use_tcp: conf['use_tcp'] || false
        }
      end

      def self.pool_size
        Gitlab::Database.main.pool_size
      end

      # Returns true if load balancing is to be enabled.
      def self.enable?
        return false if Gitlab::Runtime.rake?
        return false unless self.configured?

        true
      end

      # Returns true if load balancing has been configured. Since
      # Sidekiq does not currently use load balancing, we
      # may want Web application servers to detect replication lag by
      # posting the write location of the database if load balancing is
      # configured.
      def self.configured?
        hosts.any? || service_discovery_enabled?
      end

      def self.start_service_discovery
        return unless service_discovery_enabled?

        ServiceDiscovery.new(service_discovery_configuration).start
      end

      # Configures proxying of requests.
      def self.configure_proxy(proxy = ConnectionProxy.new(hosts))
        @proxy = proxy

        # This hijacks the "connection" method to ensure both
        # `ActiveRecord::Base.connection` and all models use the same load
        # balancing proxy.
        ActiveRecord::Base.singleton_class.prepend(ActiveRecordProxy)
      end

      def self.active_record_models
        ActiveRecord::Base.descendants
      end

      DB_ROLES = [
        ROLE_PRIMARY = :primary,
        ROLE_REPLICA = :replica,
        ROLE_UNKNOWN = :unknown
      ].freeze

      # Returns the role (primary/replica) of the database the connection is
      # connecting to. At the moment, the connection can only be retrieved by
      # Gitlab::Database::LoadBalancer#read or #read_write or from the
      # ActiveRecord directly. Therefore, if the load balancer doesn't
      # recognize the connection, this method returns the primary role
      # directly. In future, we may need to check for other sources.
      def self.db_role_for_connection(connection)
        return ROLE_PRIMARY if !enable? || @proxy.blank?

        proxy.load_balancer.db_role_for_connection(connection)
      end
    end
  end
end
