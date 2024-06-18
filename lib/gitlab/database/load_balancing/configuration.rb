# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Configuration settings for a single LoadBalancer instance.
      class Configuration
        attr_accessor :hosts, :max_replication_difference,
          :max_replication_lag_time, :replica_check_interval,
          :service_discovery

        # Creates a configuration object for the given ActiveRecord model.
        def self.for_model(model)
          cfg = model.connection_db_config.configuration_hash.deep_symbolize_keys
          lb_cfg = cfg[:load_balancing] || {}
          config = new(model)

          if (diff = lb_cfg[:max_replication_difference])
            config.max_replication_difference = diff
          end

          if (lag = lb_cfg[:max_replication_lag_time])
            config.max_replication_lag_time = lag.to_f
          end

          if (interval = lb_cfg[:replica_check_interval])
            config.replica_check_interval = interval.to_f
          end

          if (hosts = lb_cfg[:hosts])
            config.hosts = hosts
          end

          discover = lb_cfg[:discover] || {}

          # We iterate over the known/default keys so we don't end up with
          # random keys in our configuration hash.
          config.service_discovery.each do |key, _|
            if (value = discover[key])
              config.service_discovery[key] = value
            end
          end

          config
        end

        def initialize(model, hosts = [])
          @max_replication_difference = 8.megabytes
          @max_replication_lag_time = 60.0
          @replica_check_interval = 60.0
          @model = model
          @hosts = hosts
          @service_discovery = {
            nameserver: 'localhost',
            port: 8600,
            record: nil,
            record_type: 'A',
            interval: 60,
            disconnect_timeout: 120,
            use_tcp: false,
            max_replica_pools: nil
          }
        end

        def db_config_name
          @model.connection_db_config.name.to_sym
        end

        def connection_specification_name
          @model.connection_specification_name
        end

        def db_config
          @model.connection_db_config
        end

        def pool_size
          # The pool size may change when booting up GitLab, as GitLab enforces
          # a certain number of threads. If a Configuration is memoized, this
          # can lead to incorrect pool sizes.
          #
          # To support this scenario, we always attempt to read the pool size
          # from the model's configuration.
          @model.connection_db_config.configuration_hash[:pool] ||
            Database.default_pool_size
        end

        # Returns `true` if the use of load balancing replicas should be
        # enabled.
        #
        # This is disabled for Rake tasks to ensure e.g. database migrations
        # always produce consistent results.
        def load_balancing_enabled?
          return false if Gitlab::Runtime.rake?

          hosts.any? || service_discovery_enabled?
        end

        # This is disabled for Rake tasks to ensure e.g. database migrations
        # always produce consistent results.
        def service_discovery_enabled?
          return false if Gitlab::Runtime.rake?

          service_discovery[:record].present?
        end
      end
    end
  end
end
