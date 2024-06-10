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
      InvalidPathError = Class.new(StandardError)

      class << self
        delegate :params, :url, :store, :encrypted_secrets, to: :new

        def with
          pool.with { |redis| yield redis }
        end

        def version
          with { |redis| redis.info['redis_version'] }
        end

        def pool
          @pool ||= if config_fallback &&
              config_fallback.params.except(:instrumentation_class) == params.except(:instrumentation_class)
                      config_fallback.pool
                    else
                      ConnectionPool.new(size: pool_size, name: store_name.underscore) { redis }
                    end
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
            config_file_path("redis.#{store_name.underscore}.yml"),

            # The current Redis instance may have been split off from another one
            # (e.g. TraceChunks was split off from SharedState).
            config_fallback&.config_file_name
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

        def redis
          init_redis(params)
        end

        private

        def init_redis(config)
          if config[:nodes].present?
            ::Redis::Cluster.new(config.merge({ concurrency: { model: :none } }))
          else
            ::Redis.new(config)
          end
        end
      end

      def initialize(rails_env = nil)
        @rails_env = rails_env || ::Rails.env
      end

      def params
        options = redis_store_options
        options[:command_builder] = CommandBuilder

        # avoid passing classes into options as Sidekiq scrubs the options with Marshal.dump + Marshal.load
        # ref https://github.com/sidekiq/sidekiq/blob/v7.1.6/lib/sidekiq/redis_connection.rb#L37
        #
        # this does not play well with spring enabled as the forked process references the old constant
        # we use strings to look up Gitlab::Instrumentation::Redis.storage_hash as a bypass
        options[:custom] = { instrumentation_class: self.class.store_name }

        if options[:sentinels]
          # name is required in RedisClient::SentinelConfig
          # https://github.com/redis-rb/redis-client/blob/1ab081c1d0e47df5d55e011c9390c70b2eef6731/lib/redis_client/sentinel_config.rb#L17
          options[:name] = options[:host]
          options.except(:scheme, :instrumentation_class, :host, :port)
        elsif options[:cluster]
          options[:nodes] = options[:cluster].map { |c| c.except(:scheme) }
          options.except(:scheme, :instrumentation_class, :cluster)
        else
          # remove disallowed keys as seen in
          # https://github.com/redis-rb/redis-client/blob/1ab081c1d0e47df5d55e011c9390c70b2eef6731/lib/redis_client/config.rb#L21
          options.except(:scheme, :instrumentation_class)
        end
      end

      def url
        raw_config_hash[:url]
      end

      def db
        redis_store_options[:db] || 0
      end

      def sentinels
        raw_config_hash[:sentinels]
      end

      def secret_file
        return unless defined?(Settings)

        if raw_config_hash[:secret_file].blank?
          File.join(Settings.encrypted_settings['path'], 'redis.yaml.enc')
        else
          Settings.absolute(raw_config_hash[:secret_file])
        end
      end

      def sentinels?
        sentinels && !sentinels.empty?
      end

      def store(extras = {})
        ::Redis::Store::Factory.create(params.merge(extras))
      end

      def encrypted_secrets
        # In rake tasks, we have to populate the encrypted_secrets even if the
        # file does not exist, as it is the job of one of those tasks to create
        # the file. In other cases, like when being loaded as part of spinning
        # up test environment via `scripts/setup-test-env`, we should gate on
        # the presence of the specified secret file so that
        # `Settings.encrypted`, which might not be loadable does not get
        # called. Same is the case when this library gets called by Mailroom
        # which does not have rails environment available.
        Settings.encrypted(secret_file) if (secret_file && File.exist?(secret_file)) ||
          (defined?(Gitlab::Runtime) && Gitlab::Runtime.rake?)
      end

      private

      def redis_store_options
        config = raw_config_hash
        config[:instrumentation_class] ||= self.class.instrumentation_class

        decrypted_config = parse_encrypted_config(config)
        final_config = Gitlab::Redis::ConfigGenerator.new('Redis').generate(decrypted_config)

        result = if final_config[:cluster].present?
                   final_config[:cluster] = final_config[:cluster].map do |node|
                     next node unless node.is_a?(String)

                     ::Redis::Store::Factory.extract_host_options_from_uri(node)
                   end
                   final_config
                 else
                   parse_redis_url(final_config)
                 end

        parse_client_tls_options(result)
      end

      def parse_encrypted_config(encrypted_config)
        encrypted_config.delete(:secret_file)

        decrypted_secrets = encrypted_secrets&.config
        encrypted_config.merge!(decrypted_secrets) if decrypted_secrets

        encrypted_config
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
          redis_hash[:ssl] = true if redis_hash[:scheme] == 'rediss'
          # order is important here, sentinels must be after the connection keys.
          # {url: ..., port: ..., sentinels: [...]}
          redis_hash.merge(config)
        end
      end

      def parse_client_tls_options(config)
        return config unless config&.key?(:ssl_params)

        # Only cert_file and key_file are handled in this method. ca_file and
        # ca_path are Strings, so they can be passed as-is. cert_store is not
        # currently supported.

        cert_file = config[:ssl_params].delete(:cert_file)
        key_file = config[:ssl_params].delete(:key_file)

        if cert_file
          unless ::File.exist?(cert_file)
            raise InvalidPathError,
              "Certificate file #{cert_file} specified in in `resque.yml` does not exist."
          end

          config[:ssl_params][:cert] = OpenSSL::X509::Certificate.new(File.read(cert_file))
        end

        if key_file
          unless ::File.exist?(key_file)
            raise InvalidPathError,
              "Key file #{key_file} specified in in `resque.yml` does not exist."
          end

          config[:ssl_params][:key] = OpenSSL::PKey.read(File.read(key_file))
        end

        config
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
