module Gitlab
  class Redis
    CACHE_NAMESPACE = 'cache:gitlab'
    SESSION_NAMESPACE = 'session:gitlab'
    SIDEKIQ_NAMESPACE = 'resque:gitlab'

    attr_reader :url

    # To be thread-safe we must be careful when writing the class instance
    # variables @url and @pool. Because @pool depends on @url we need two
    # mutexes to prevent deadlock.
    URL_MUTEX = Mutex.new
    POOL_MUTEX = Mutex.new
    private_constant :URL_MUTEX, :POOL_MUTEX

    def self.url
      @url || URL_MUTEX.synchronize { @url = new.url }
    end

    def self.with
      if @pool.nil?
        POOL_MUTEX.synchronize do
          @pool = ConnectionPool.new { ::Redis.new(url: url) }
        end
      end
      @pool.with { |redis| yield redis }
    end

    def self.redis_store_options
      url = new.url
      redis_config_hash = ::Redis::Store::Factory.extract_host_options_from_uri(url)
      # Redis::Store does not handle Unix sockets well, so let's do it for them
      redis_uri = URI.parse(url)
      if redis_uri.scheme == 'unix'
        redis_config_hash[:path] = redis_uri.path
      end
      redis_config_hash
    end

    def initialize(rails_env = nil)
      rails_env ||= Rails.env
      config_file = File.expand_path('../../../config/resque.yml', __FILE__)

      @url = "redis://localhost:6379"
      if File.exist?(config_file)
        @url = YAML.load_file(config_file)[rails_env]
      end
    end
  end
end
