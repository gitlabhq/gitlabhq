# frozen_string_literal: true

if Gitlab::Database::LoadBalancing.enable?
  Gitlab::Database.main.disable_prepared_statements

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
  end

  Gitlab::Database::LoadBalancing.configure_proxy

  # This needs to be executed after fork of clustered processes
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    # For Host-based LB, we need to re-connect as Rails discards connections on fork
    Gitlab::Database::LoadBalancing.configure_proxy

    # Service discovery must be started after configuring the proxy, as service
    # discovery depends on this.
    Gitlab::Database::LoadBalancing.start_service_discovery
  end
end
