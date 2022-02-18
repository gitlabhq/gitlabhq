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

          config.reuse_primary_connection!

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
            use_tcp: false
          }

          # Temporary model for GITLAB_LOAD_BALANCING_REUSE_PRIMARY_
          # To be removed with FF
          @primary_model = nil
        end

        def db_config_name
          @model.connection_db_config.name.to_sym
        end

        # With connection re-use the primary connection can be overwritten
        # to be used from different model
        def primary_connection_specification_name
          primary_model_or_model_if_enabled.connection_specification_name
        end

        def primary_model_or_model_if_enabled
          if force_no_sharing_primary_model?
            @model
          else
            @primary_model || @model
          end
        end

        def force_no_sharing_primary_model?
          return false unless @primary_model # Doesn't matter since we don't have an overriding primary model
          return false unless ::Gitlab::SafeRequestStore.active?

          ::Gitlab::SafeRequestStore.fetch(:force_no_sharing_primary_model) do
            ::Feature::FlipperFeature.table_exists? && ::Feature.enabled?(:force_no_sharing_primary_model, default_enabled: :yaml)
          end
        end

        def replica_db_config
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

        # TODO: This is temporary code to allow re-use of primary connection
        # if the two connections are pointing to the same host. This is needed
        # to properly support transaction visibility.
        #
        # This behavior is required to support [Phase 3](https://gitlab.com/groups/gitlab-org/-/epics/6160#progress).
        # This method is meant to be removed as soon as it is finished.
        #
        # The remapping is done as-is:
        #   export GITLAB_LOAD_BALANCING_REUSE_PRIMARY_<name-of-connection>=<new-name-of-connection>
        #
        # Ex.:
        #   export GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci=main
        #
        def reuse_primary_connection!
          new_connection = ENV["GITLAB_LOAD_BALANCING_REUSE_PRIMARY_#{db_config_name}"]
          return unless new_connection.present?

          @primary_model = Gitlab::Database.database_base_models[new_connection.to_sym]

          unless @primary_model
            raise "Invalid value for 'GITLAB_LOAD_BALANCING_REUSE_PRIMARY_#{db_config_name}=#{new_connection}'"
          end
        end
      end
    end
  end
end
