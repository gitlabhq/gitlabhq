# frozen_string_literal: true

# We need this require for MailRoom
require_relative 'wrapper' unless defined?(::Gitlab::Redis::Wrapper)

module Gitlab
  module Redis
    class Queues < ::Gitlab::Redis::Wrapper
      SIDEKIQ_NAMESPACE = 'resque:gitlab'
      MAILROOM_NAMESPACE = 'mail_room:gitlab'
      SIDEKIQ_MAIN_SHARD_INSTANCE_NAME = 'main'

      class << self
        def shard_name
          SIDEKIQ_MAIN_SHARD_INSTANCE_NAME
        end

        def sidekiq_redis
          @sidekiq_redis ||= Sidekiq::RedisConnection.create(
            { size: pool_size, pool_name: store_name.underscore }.merge(params))
        end

        # extra instances need to have the queues_shard_ prefix
        def instances
          @instances ||= begin
            shard_configs = load_shard_config

            if shard_configs.empty?
              { SIDEKIQ_MAIN_SHARD_INSTANCE_NAME => self }
            else
              extra_instances = shard_configs.map do |key, value|
                # Dynamically creates child classes of Wrapper and set them using the store name.
                # The corresponding instrumentation classes is defined in in lib/gitlab/instrumentation/redis.rb
                #
                # The extra instance classes will be part of Gitlab::Redis::ALL_CLASSES which
                # contains *Gitlab::Redis::Queues.instances.values. This allows the dynamically created classes to
                # behave like other defined Wrapper classes (e.e. Cache, SharedState).
                #
                # The dynamically created classes will have Gitlab::Redis::QueuesShardXXX where XXX is user-defined.
                new_klass = create_shard_class(key, value)
                Gitlab::Redis.const_set(new_klass.store_name, new_klass)
                new_klass
              end

              extra_instances << self
              extra_instances.index_by(&:shard_name)
            end
          end
        end

        private

        def load_shard_config
          config_files = Dir.glob(File.join(rails_root, 'config', "redis.yml"))
          return {} if config_files.empty?

          redis_yml = YAML.safe_load(ERB.new(File.read(config_files.first)).result, aliases: true)
          if redis_yml.nil? || redis_yml.empty? || redis_yml[::Rails.env].nil? || !redis_yml[::Rails.env].is_a?(Hash)
            return {}
          end

          # Extra queue instances should follow the format of `queues_shard_xxxx` in the redis.yml file.
          redis_yml[::Rails.env].filter do |k, _v|
            k.include?('queues_shard_')
          end
        end

        def create_shard_class(shard_name, shard_config)
          Class.new(::Gitlab::Redis::Wrapper) do
            define_method(:fetch_config) do
              shard_config
            end

            # We use `define_singleton_method` to be able to access the outer scope
            define_singleton_method(:pool) do
              @pool ||= ConnectionPool.new(size: pool_size, name: shard_name) do
                ::Redis.new(params)
              end
            end

            define_singleton_method(:sidekiq_redis) do
              @sidekiq_redis ||= Sidekiq::RedisConnection.create(
                { size: pool_size, pool_name: shard_name }.merge(params))
            end

            define_singleton_method(:shard_name) do
              shard_name
            end

            define_singleton_method(:store_name) do
              shard_name.camelize
            end
          end
        end
      end
    end
  end
end
