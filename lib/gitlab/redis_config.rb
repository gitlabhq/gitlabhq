module Gitlab
  class RedisConfig
    attr_reader :url

    def self.url
      new.url
    end
    
    def self.redis_store_options
      url = new.url
      redis_config_hash = Redis::Store::Factory.extract_host_options_from_uri(url)
      # Redis::Store does not handle Unix sockets well, so let's do it for them
      redis_uri = URI.parse(url)
      if redis_uri.scheme == 'unix'
        redis_config_hash[:path] = redis_uri.path
      end
      redis_config_hash
    end

    def initialize(rails_env=nil)
      rails_env ||= Rails.env
      config_file = File.expand_path('../../../config/resque.yml', __FILE__)
  
      @url = "redis://localhost:6379"
      if File.exists?(config_file)
        @url =YAML.load_file(config_file)[rails_env]
      end
    end
  end
end
