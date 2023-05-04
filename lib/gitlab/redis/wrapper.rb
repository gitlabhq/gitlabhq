# frozen_string_literal: true

# This file should only be used by sub-classes, not directly by any clients of the sub-classes

# Explicitly load parts of ActiveSupport because MailRoom does not load
# Rails.
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

# Explicitly load Redis::Store::Factory so we can read Redis configuration in
# TestEnv
require 'redis/store/factory'

module Gitlab
  module Redis
    class Wrapper
      class << self
        delegate :params, :url, :store, to: :new

        def with
          pool.with { |redis| yield redis }
        end

        def version
          with { |redis| redis.info['redis_version'] }
        end

        def pool
          @pool ||= ConnectionPool.new(size: pool_size) { redis }
        end

        def pool_size
          # heuristic constant 5 should be a config setting somewhere -- related to CPU count?
          size = 5
          if Gitlab::Runtime.multi_threaded?
            size += Gitlab::Runtime.max_threads
          end

          size
        end

        def config_file_path(filename)
          path = File.join(rails_root, 'config', filename)
          return path if File.file?(path)
        end

        # We need this local implementation of Rails.root because MailRoom
        # doesn't load Rails.
        def rails_root
          File.expand_path('../../..', __dir__)
        end

        def config_file_name
          [
            # Instance specific config sources:
            ENV["GITLAB_REDIS_#{store_name.underscore.upcase}_CONFIG_FILE"],
            config_file_path("redis.#{store_name.underscore}.yml"),

            # The current Redis instance may have been split off from another one
            # (e.g. TraceChunks was split off from SharedState).
            config_fallback&.config_file_name,

            # Global config sources:
            ENV['GITLAB_REDIS_CONFIG_FILE']
          ].compact.first
        end

        def redis_yml_path
          File.join(rails_root, 'config/redis.yml')
        end

        def store_name
          name.demodulize
        end

        def config_fallback
          nil
        end

        def instrumentation_class
          return unless defined?(::Gitlab::Instrumentation::Redis)

          "::Gitlab::Instrumentation::Redis::#{store_name}".constantize
        end

        private

        def redis
          ::Redis.new(params)
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

      def db
        redis_store_options[:db]
      end

      def sentinels
        raw_config_hash[:sentinels]
      end

      def sentinels?
        sentinels && !sentinels.empty?
      end

      def store(extras = {})
        ::Redis::Store::Factory.create(redis_store_options.merge(extras))
      end

      private

      def redis_store_options
        config = raw_config_hash
        config[:instrumentation_class] ||= self.class.instrumentation_class

        if config[:cluster].present?
          config[:db] = 0 # Redis Cluster only supports db 0
          config
        else
          parse_redis_url(config)
        end
      end

      def parse_redis_url(config)
        redis_url = config.delete(:url)
        redis_uri = URI.parse(redis_url)

        if redis_uri.scheme == 'unix'
          # Redis::Store does not handle Unix sockets well, so let's do it for them
          config[:path] = redis_uri.path
          query = redis_uri.query
          unless query.nil?
            queries = CGI.parse(redis_uri.query)
            db_numbers = queries["db"] if queries.key?("db")
            config[:db] = db_numbers[0].to_i if db_numbers.any?
          end

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

        return { url: '' } if config_data.nil?
        return { url: config_data } if config_data.is_a?(String)

        config_data.deep_symbolize_keys
      end

      def fetch_config
        redis_yml = read_yaml(self.class.redis_yml_path).fetch(@rails_env, {})
        instance_config_yml = read_yaml(self.class.config_file_name)[@rails_env]
        resque_yml = read_yaml(self.class.config_file_path('resque.yml'))[@rails_env]

        [
          redis_yml[self.class.store_name.underscore],
          # There are installations out there where the lowest priority config source (resque.yml) contains bogus
          # values. In those cases, the configuration should be read for the instance we originated from (the
          # "config_fallback"), either from its specific config file or from redis.yml, before falling back to
          # resque.yml.
          instance_config_yml,
          self.class.config_fallback && redis_yml[self.class.config_fallback.store_name.underscore],
          resque_yml
        ].compact.first
      end

      def read_yaml(path)
        YAML.safe_load(ERB.new(File.read(path.to_s)).result, aliases: true) || {}
      rescue Errno::ENOENT
        {}
      end
    end
  end
end
