# rubocop:disable GitlabSecurity/PublicSend

module Gitlab
  module Database
    module LoadBalancing
      # The connection proxy to use for load balancing (if enabled).
      cattr_accessor :proxy

      LOG_TAG = 'DB-LB'.freeze

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

      # Returns a Hash containing the load balancing configuration.
      def self.configuration
        ActiveRecord::Base.configurations[Rails.env]['load_balancing'] || {}
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
          interval: conf['interval'] || 60,
          disconnect_timeout: conf['disconnect_timeout'] || 120
        }
      end

      def self.log(level, message)
        Rails.logger.tagged(LOG_TAG) do
          Rails.logger.send(level, message)
        end
      end

      def self.pool_size
        ActiveRecord::Base.configurations[Rails.env]['pool']
      end

      # Returns true if load balancing is to be enabled.
      def self.enable?
        return false unless ::License.feature_available?(:db_load_balancing)
        return false if program_name == 'rake' || Sidekiq.server?
        return false unless Database.postgresql?

        hosts.any? || service_discovery_enabled?
      end

      def self.program_name
        @program_name ||= File.basename($0)
      end

      def self.start_service_discovery
        return unless service_discovery_enabled?

        ServiceDiscovery.new(service_discovery_configuration).start
      end

      # Configures proxying of requests.
      def self.configure_proxy
        self.proxy = ConnectionProxy.new(hosts)

        # This hijacks the "connection" method to ensure both
        # `ActiveRecord::Base.connection` and all models use the same load
        # balancing proxy.
        ActiveRecord::Base.singleton_class.prepend(ActiveRecordProxy)
      end

      def self.active_record_models
        ActiveRecord::Base.descendants
      end
    end
  end
end
