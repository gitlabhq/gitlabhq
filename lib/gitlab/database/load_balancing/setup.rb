# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Class for setting up load balancing of a specific model.
      class Setup
        attr_reader :configuration

        def initialize(model, start_service_discovery: false)
          @model = model
          @configuration = Configuration.for_model(model)
          @start_service_discovery = start_service_discovery
        end

        def setup
          disable_prepared_statements
          setup_load_balancer
          setup_service_discovery
        end

        def disable_prepared_statements
          db_config_object = @model.connection_db_config
          config =
            db_config_object.configuration_hash.merge(prepared_statements: false)

          hash_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            db_config_object.env_name,
            db_config_object.name,
            config
          )

          @model.establish_connection(hash_config)
        end

        def setup_load_balancer
          lb = LoadBalancer.new(configuration)

          # We just use a simple `class_attribute` here so we don't need to
          # inject any modules and/or expose unnecessary methods.
          @model.class_attribute(:connection)
          @model.class_attribute(:sticking)

          @model.connection = ConnectionProxy.new(lb)
          @model.sticking = Sticking.new(lb)
        end

        def setup_service_discovery
          return unless configuration.service_discovery_enabled?

          lb = @model.connection.load_balancer
          sv = ServiceDiscovery.new(lb, **configuration.service_discovery)

          sv.perform_service_discovery

          sv.start if @start_service_discovery
        end
      end
    end
  end
end
