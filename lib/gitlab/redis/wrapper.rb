# frozen_string_literal: true

# This file should only be used by sub-classes, not directly by any clients of the sub-classes

# Explicitly load parts of ActiveSupport because MailRoom does not load
# Rails.
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

module Gitlab
  module Redis
    class Wrapper
      class << self
        delegate :params, :url, to: :new

        def with
          pool.with { |redis| yield redis }
        end

        def version
          with { |redis| redis.info['redis_version'] }
        end

        def pool
          @pool ||= ConnectionPool.new(size: pool_size) { ::Redis.new(params) }
        end

        def pool_size
          # heuristic constant 5 should be a config setting somewhere -- related to CPU count?
          size = 5
          if Gitlab::Runtime.multi_threaded?
            size += Gitlab::Runtime.max_threads
          end

          size
        end

        def _raw_config
          return @_raw_config if defined?(@_raw_config)

          @_raw_config =
            begin
              if filename = config_file_name
                ERB.new(File.read(filename)).result.freeze
              else
                false
              end
            rescue Errno::ENOENT
              false
            end
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
            # (e.g. TraceChunks was split off from SharedState). There are
            # installations out there where the lowest priority config source
            # (resque.yml) contains bogus values. In those cases, config_file_name
            # should resolve to the instance we originated from (the
            # "config_fallback") rather than resque.yml.
            config_fallback&.config_file_name,

            # Global config sources:
            ENV['GITLAB_REDIS_CONFIG_FILE'],
            config_file_path('resque.yml')
          ].compact.first
        end

        def store_name
          name.demodulize
        end

        def config_fallback
          nil
        end

        def instrumentation_class
          "::Gitlab::Instrumentation::Redis::#{store_name}".constantize
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

        config[:instrumentation_class] ||= self.class.instrumentation_class

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

        if config_data
          config_data.is_a?(String) ? { url: config_data } : config_data.deep_symbolize_keys
        else
          { url: '' }
        end
      end

      def fetch_config
        return false unless self.class._raw_config

        yaml = YAML.safe_load(self.class._raw_config, aliases: true)

        # If the file has content but it's invalid YAML, `load` returns false
        if yaml
          yaml.fetch(@rails_env, false)
        else
          false
        end
      end
    end
  end
end
