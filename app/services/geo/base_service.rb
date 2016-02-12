module Geo
  class BaseService

    NAMESPACE = :geo

    protected

    def redis_connection
      redis_config_file = Rails.root.join('config', 'resque.yml')

      redis_url_string = if File.exists?(redis_config_file)
                           YAML.load_file(redis_config_file)[Rails.env]
                         else
                           'redis://localhost:6379'
                         end

      Redis::Namespace.new(NAMESPACE, redis: Redis.new(url: redis_url_string))
    end
  end
end
