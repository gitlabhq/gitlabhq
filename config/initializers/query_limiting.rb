if Gitlab::QueryLimiting.enable?
  require_dependency 'gitlab/query_limiting/active_support_subscriber'
  require_dependency 'gitlab/query_limiting/transaction'
  require_dependency 'gitlab/query_limiting/middleware'

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::QueryLimiting::Middleware)
  end
end
