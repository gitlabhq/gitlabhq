Rails.application.configure do |config|
  config.middleware.use(Gitlab::RequestProfiler::Middleware)
end
