# Custom Redis configuration
config_file = Rails.root.join('config', 'resque.yml')

resque_url =  if ENV.key?('GITLAB_REDIS_URL')
                ENV['GITLAB_REDIS_URL']
              elsif File.exists?(config_file)
                YAML.load_file(config_file)[Rails.env]
              else
                "redis://localhost:6379"
              end

Sidekiq.configure_server do |config|
  config.redis = {
    url: resque_url,
    namespace: 'resque:gitlab'
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: resque_url,
    namespace: 'resque:gitlab'
  }
end
