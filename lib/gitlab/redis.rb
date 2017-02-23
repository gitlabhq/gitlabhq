# This file should not have any direct dependency on Rails environment
# please require all dependencies below:
require 'active_support/core_ext/hash/keys'

module Gitlab
  class Redis
    CACHE_NAMESPACE = 'cache:gitlab'.freeze
    SESSION_NAMESPACE = 'session:gitlab'.freeze
    SIDEKIQ_NAMESPACE = 'resque:gitlab'.freeze
    MAILROOM_NAMESPACE = 'mail_room:gitlab'.freeze
    DEFAULT_REDIS_URL = 'redis://localhost:6379'.freeze
    CONFIG_FILE = File.expand_path('../../config/resque.yml', __dir__)

    class << self
      delegate :params, :url, to: :new

      def with
        @pool ||= ConnectionPool.new(size: pool_size) { ::Redis.new(params) }
        @pool.with { |redis| yield redis }
      end

      def pool_size
        if Sidekiq.server?
          # the pool will be used in a multi-threaded context
          Sidekiq.options[:concurrency] + 5
        else
          # probably this is a Unicorn process, so single threaded
          5
        end
      end

      def _raw_config
        return @_raw_config if defined?(@_raw_config)

        begin
          @_raw_config = ERB.new(File.read(CONFIG_FILE)).result.freeze
        rescue Errno::ENOENT
          @_raw_config = false
        end

        @_raw_config
      end
    end

    def initialize(rails_env = nil)
      @rails_env = rails_env || ::Rails.env
    end

    def params
      redis_store_options
    end

    def url
      raw_config_hash[:url]
    end

    def sentinels
      raw_config_hash[:sentinels]
    end

    def sentinels?
      sentinels && !sentinels.empty?
    end

    private

    def redis_store_options
      config = raw_config_hash
      redis_url = config.delete(:url)
      redis_uri = URI.parse(redis_url)

      if redis_uri.scheme == 'unix'
        # Redis::Store does not handle Unix sockets well, so let's do it for them
        config[:path] = redis_uri.path
        config
      else
        redis_hash = ::Redis::Store::Factory.extract_host_options_from_uri(redis_url)
        # order is important here, sentinels must be after the connection keys.
        # {url: ..., port: ..., sentinels: [...]}
        redis_hash.merge(config)
      end
    end

    def raw_config_hash
      config_data = fetch_config

      if config_data
        config_data.is_a?(String) ? { url: config_data } : config_data.deep_symbolize_keys
      else
        { url: DEFAULT_REDIS_URL }
      end
    end

    def fetch_config
      self.class._raw_config ? YAML.load(self.class._raw_config)[@rails_env] : false
    end
  end
end
