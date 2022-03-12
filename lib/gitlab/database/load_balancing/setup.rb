# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Class for setting up load balancing of a specific model.
      class Setup
        attr_reader :model, :configuration

        def initialize(model, start_service_discovery: false)
          @model = model
          @configuration = Configuration.for_model(model)
          @start_service_discovery = start_service_discovery
        end

        def setup
          configure_connection
          setup_connection_proxy
          setup_service_discovery
          setup_feature_flag_to_model_load_balancing
        end

        def configure_connection
          db_config_object = @model.connection_db_config

          hash = db_config_object.configuration_hash.merge(
            prepared_statements: false,
            pool: Gitlab::Database.default_pool_size
          )

          hash_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            db_config_object.env_name,
            db_config_object.name,
            hash
          )

          @model.establish_connection(hash_config)
        end

        def setup_connection_proxy
          # We just use a simple `class_attribute` here so we don't need to
          # inject any modules and/or expose unnecessary methods.
          setup_class_attribute(:load_balancer, load_balancer)
          setup_class_attribute(:connection, ConnectionProxy.new(load_balancer))
          setup_class_attribute(:sticking, Sticking.new(load_balancer))
        end

        # TODO: This is temporary code to gradually redirect traffic to use
        # a dedicated DB replicas, or DB primaries (depending on configuration)
        # This implements a sticky behavior for the current request if enabled.
        #
        # This is needed for Phase 3 and Phase 4 of application rollout
        # https://gitlab.com/groups/gitlab-org/-/epics/6160#progress
        #
        # If `GITLAB_USE_MODEL_LOAD_BALANCING` is set, its value is preferred
        # Otherwise, a `use_model_load_balancing` FF value is used
        def setup_feature_flag_to_model_load_balancing
          return if active_record_base?

          @model.singleton_class.prepend(ModelLoadBalancingFeatureFlagMixin)
        end

        def setup_service_discovery
          return unless configuration.service_discovery_enabled?

          sv = ServiceDiscovery.new(load_balancer, **configuration.service_discovery)

          sv.perform_service_discovery

          sv.start if @start_service_discovery
        end

        def load_balancer
          @load_balancer ||= LoadBalancer.new(configuration)
        end

        private

        def setup_class_attribute(attribute, value)
          @model.class_attribute(attribute)
          @model.public_send("#{attribute}=", value) # rubocop:disable GitlabSecurity/PublicSend
        end

        def active_record_base?
          @model == ActiveRecord::Base
        end

        module ModelLoadBalancingFeatureFlagMixin
          extend ActiveSupport::Concern

          def use_model_load_balancing?
            # Cache environment variable and return env variable first if defined
            default_use_model_load_balancing_env = Gitlab.dev_or_test_env? || nil
            use_model_load_balancing_env = Gitlab::Utils.to_boolean(ENV.fetch('GITLAB_USE_MODEL_LOAD_BALANCING', default_use_model_load_balancing_env))

            unless use_model_load_balancing_env.nil?
              return use_model_load_balancing_env
            end

            # Check a feature flag using RequestStore (if active)
            return false unless Gitlab::SafeRequestStore.active?

            Gitlab::SafeRequestStore.fetch(:use_model_load_balancing) do
              Feature.enabled?(:use_model_load_balancing, default_enabled: :yaml)
            end
          end

          def connection
            use_model_load_balancing? ? super : ApplicationRecord.connection
          end
        end
      end
    end
  end
end
