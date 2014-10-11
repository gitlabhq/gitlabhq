# Custom Redis configuration
resque_url = Gitlab.config.redis.redis_url

Sidekiq.configure_server do |config|
  config.redis = {
    url: resque_url,
    namespace: 'resque:gitlab'
  }

  config.server_middleware do |chain|
    chain.add Gitlab::SidekiqMiddleware::ArgumentsLogger
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: resque_url,
    namespace: 'resque:gitlab'
  }
end
