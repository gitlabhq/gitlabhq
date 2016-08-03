require 'gitlab/request_profiler/middleware'

Rails.application.configure do |config|
  config.middleware.use(Gitlab::RequestProfiler::Middleware)
end
