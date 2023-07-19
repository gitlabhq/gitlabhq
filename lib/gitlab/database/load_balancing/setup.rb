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

          ::Gitlab::Database::LoadBalancing::Logger.debug(
            event: :setup,
            model: model.name,
            start_service_discovery: @start_service_discovery
          )
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

        def setup_service_discovery
          return unless configuration.service_discovery_enabled?

          sv = ServiceDiscovery.new(load_balancer, **configuration.service_discovery)

          load_balancer.service_discovery = sv

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
      end
    end
  end
end
