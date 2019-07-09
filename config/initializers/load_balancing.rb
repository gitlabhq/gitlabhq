# frozen_string_literal: true

# We need to run this initializer after migrations are done so it doesn't fail on CI

Gitlab.ee do
  if ActiveRecord::Base.connected? && ActiveRecord::Base.connection.data_source_exists?('licenses')
    if Gitlab::Database::LoadBalancing.enable?
      Gitlab::Database.disable_prepared_statements

      Gitlab::Application.configure do |config|
        config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
      end

      Gitlab::Database::LoadBalancing.configure_proxy

      # This needs to be executed after fork of clustered processes
      Gitlab::Cluster::LifecycleEvents.on_worker_start do
        # Service discovery must be started after configuring the proxy, as service
        # discovery depends on this.
        Gitlab::Database::LoadBalancing.start_service_discovery
      end

    end
  end
end
