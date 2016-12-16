Rails.application.configure do |config|
  config.middleware.use(Gitlab::Middleware::Multipart)
end
