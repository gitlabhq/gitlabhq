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
        unless load_balancing_proxy = ActiveRecord::Base.load_balancing_proxy
          Gitlab::ErrorTracking.track_exception(
            ProxyNotConfiguredError.new(
              "Attempting to access the database load balancing proxy, but it wasn't configured.\n" \
              "Did you forget to call '#{self.name}.configure_proxy'?"
            ))
        end

        load_balancing_proxy
      end

      # Returns a Hash containing the load balancing configuration.
      def self.configuration
        @configuration ||= Configuration.for_model(ActiveRecord::Base)
      end

      # Returns true if load balancing is to be enabled.
      def self.enable?
        return false if Gitlab::Runtime.rake?

        configured?
      end

      def self.configured?
        configuration.load_balancing_enabled? ||
          configuration.service_discovery_enabled?
      end

      def self.start_service_discovery
        return unless configuration.service_discovery_enabled?

        ServiceDiscovery
          .new(proxy.load_balancer, **configuration.service_discovery)
          .start
      end

      # Configures proxying of requests.
      def self.configure_proxy
        lb = LoadBalancer.new(configuration, primary_only: !enable?)
        ActiveRecord::Base.load_balancing_proxy = ConnectionProxy.new(lb)

        # Populate service discovery immediately if it is configured
        if configuration.service_discovery_enabled?
          ServiceDiscovery
            .new(lb, **configuration.service_discovery)
            .perform_service_discovery
        end
      end

      DB_ROLES = [
        ROLE_PRIMARY = :primary,
        ROLE_REPLICA = :replica,
        ROLE_UNKNOWN = :unknown
      ].freeze

      # Returns the role (primary/replica) of the database the connection is
      # connecting to.
      def self.db_role_for_connection(connection)
        db_config = Database.db_config_for_connection(connection)
        return ROLE_UNKNOWN unless db_config

        if db_config.name.ends_with?(LoadBalancer::REPLICA_SUFFIX)
          ROLE_REPLICA
        else
          ROLE_PRIMARY
        end
      end
    end
  end
end
