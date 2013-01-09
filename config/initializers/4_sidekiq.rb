# Custom Redis configuration
config_file = Rails.root.join('config', 'resque.yml')

resque_url = if File.exists?(config_file)
               YAML.load_file(config_file)[Rails.env]
             else
               "localhost:6379"
             end

Sidekiq.configure_server do |config|
  config.redis = {
    url: "redis://#{resque_url}",
    namespace: 'resque:gitlab'
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "redis://#{resque_url}",
    namespace: 'resque:gitlab'
  }
end
