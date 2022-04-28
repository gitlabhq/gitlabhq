# frozen_string_literal: true

Rails.application.configure do |config|
  config.middleware.use(Gitlab::Middleware::Speedscope)
  config.middleware.use(Gitlab::Middleware::MemoryReport)
end
