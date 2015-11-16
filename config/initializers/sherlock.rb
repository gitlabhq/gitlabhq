if Gitlab::Sherlock.enabled?
  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Sherlock::Middleware)
  end
end
