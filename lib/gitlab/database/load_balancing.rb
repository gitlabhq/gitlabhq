# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # The exceptions raised for connection errors.
      CONNECTION_ERRORS = [
        PG::ConnectionBad,
        PG::ConnectionDoesNotExist,
        PG::ConnectionException,
        PG::ConnectionFailure,
        PG::UnableToSend,
        # During a failover this error may be raised when
        # writing to a primary.
        PG::ReadOnlySqlTransaction,
        # This error is raised when we can't connect to the database in the
        # first place (e.g. it's offline or the hostname is incorrect).
        ActiveRecord::ConnectionNotEstablished
      ].freeze

      def self.proxy
        ActiveRecord::Base.load_balancing_proxy
      end

      # Returns a Hash containing the load balancing configuration.
      def self.configuration
        @configuration ||= Configuration.for_model(ActiveRecord::Base)
      end

      # Returns `true` if the use of load balancing replicas should be enabled.
      #
      # This is disabled for Rake tasks to ensure e.g. database migrations
      # always produce consistent results.
      def self.enable_replicas?
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

      def self.perform_service_discovery
        return unless configuration.service_discovery_enabled?

        ServiceDiscovery
          .new(proxy.load_balancer, **configuration.service_discovery)
          .perform_service_discovery
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
