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
            pool: Gitlab::Database::LoadBalancing.default_pool_size
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

          # By default all base models use LB,
          # this is disabled using SkipLoadBalancer in Feature::FlipperRecord
          setup_class_attribute(:uses_load_balancer, true)

          # By default gets LoadBalancing::ConnectionProxy instance from the above defined class attribute,
          # then overwrites if a particular class (eg: Feature::FlipperRecord) extends SkipLoadBalancer.
          # 'retrieve_connection' connection is used since the default 'connection' got deprecated.
          connection_proxy = @model.connection
          @model.singleton_class.define_method(:connection) do
            uses_load_balancer ? connection_proxy : retrieve_connection
          end

          @model.singleton_class.define_method(:lease_connection) do
            uses_load_balancer ? connection : super()
          end

          @model.singleton_class.define_method(:with_connection) do |*args, **kwargs, &block|
            if uses_load_balancer
              # The original rails with_connection would return the connection to the pool,
              # but here we don't know if it's a primary or replica connection yet, so we keep it checked out for
              # the duration of the request
              block&.call(connection)
            else
              super(*args, **kwargs, &block)
            end
          end
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
