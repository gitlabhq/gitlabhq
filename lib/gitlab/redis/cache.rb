# please require all dependencies below:
require_relative 'wrapper' unless defined?(::Gitlab::Redis::Wrapper)

module Gitlab
  module Redis
    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'.freeze
      DEFAULT_REDIS_CACHE_URL = 'redis://localhost:6380'.freeze
      REDIS_CACHE_CONFIG_ENV_VAR_NAME = 'GITLAB_REDIS_CACHE_CONFIG_FILE'.freeze
      if defined?(::Rails) && ::Rails.root.present?
        DEFAULT_REDIS_CACHE_CONFIG_FILE_NAME = ::Rails.root.join('config', 'redis.cache.yml').freeze
      end

      class << self
        def default_url
          DEFAULT_REDIS_CACHE_URL
        end

        def config_file_name
          # if ENV set for this class, use it even if it points to a file does not exist
          file_name = ENV[REDIS_CACHE_CONFIG_ENV_VAR_NAME]
          return file_name unless file_name.nil?

          # otherwise, if config files exists for this class, use it
          file_name = File.expand_path(DEFAULT_REDIS_CACHE_CONFIG_FILE_NAME, __dir__)
          return file_name if File.file?(file_name)

          # this will force use of DEFAULT_REDIS_QUEUES_URL when config file is absent
          super
        end
      end
    end
  end
end
