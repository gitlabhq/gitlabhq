if Gitlab::Database::LoadBalancing.enable?
  Gitlab::Database.disable_prepared_statements

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Database::LoadBalancing::RackMiddleware)
  end

  Gitlab::Database::LoadBalancing.configure_proxy
end
