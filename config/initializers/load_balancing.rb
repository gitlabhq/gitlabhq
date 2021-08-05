# frozen_string_literal: true

ActiveRecord::Base.singleton_class.attr_accessor :load_balancing_proxy

if Gitlab::Database::LoadBalancing.enable?
  Gitlab::Database.main.disable_prepared_statements

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
  end

  # This hijacks the "connection" method to ensure both
  # `ActiveRecord::Base.connection` and all models use the same load
  # balancing proxy.
  ActiveRecord::Base.singleton_class.prepend(Gitlab::Database::LoadBalancing::ActiveRecordProxy)

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
