# We need to run this initializer after migrations are done so it doesn't fail on CI
if ActiveRecord::Base.connected? && ActiveRecord::Base.connection.table_exists?('licenses')
  if Gitlab::Database::LoadBalancing.enable?
    Gitlab::Database.disable_prepared_statements

    Gitlab::Application.configure do |config|
      config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
    end

    Gitlab::Database::LoadBalancing.configure_proxy

    # Service discovery must be started after configuring the proxy, as service
    # discovery depends on this.
    Gitlab::Database::LoadBalancing.start_service_discovery
  end
end
