Rails.application.config.middleware.use(Gitlab::Middleware::UnicornTimeoutLogger)
