# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Configuration settings for a single LoadBalancer instance.
      class Configuration
        attr_accessor :hosts, :max_replication_difference,
                      :max_replication_lag_time, :replica_check_interval,
                      :service_discovery, :pool_size, :model

        # Creates a configuration object for the given ActiveRecord model.
        def self.for_model(model)
          cfg = model.connection_db_config.configuration_hash
          lb_cfg = cfg[:load_balancing] || {}
          config = new(model)

          if (size = cfg[:pool])
            config.pool_size = size
          end

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

          discover = (lb_cfg[:discover] || {}).symbolize_keys

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
          @pool_size = Database.default_pool_size
          @service_discovery = {
            nameserver: 'localhost',
            port: 8600,
            record: nil,
            record_type: 'A',
            interval: 60,
            disconnect_timeout: 120,
            use_tcp: false
          }
        end

        def load_balancing_enabled?
          hosts.any? || service_discovery_enabled?
        end

        def service_discovery_enabled?
          service_discovery[:record].present?
        end
      end
    end
  end
end
