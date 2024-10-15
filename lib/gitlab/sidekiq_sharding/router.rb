# frozen_string_literal: true

module Gitlab
  module SidekiqSharding
    class Router
      class << self
        def enabled?
          Gitlab::Redis::Queues.instances.size > 1 && Feature.enabled?(:enable_sidekiq_shard_router, type: :ops)
        end

        def get_shard_instance(store_name)
          store_name = route_to(store_name)
          instance = Gitlab::Redis::Queues.instances[store_name]

          # To guard against setups with a configured config/gitlab.yml but stale config/redis.yml
          if instance.nil?
            store_name = Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME
            instance = Gitlab::Redis::Queues.instances[Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME]
          end

          [
            store_name,
            instance.sidekiq_redis
          ]
        end

        def route(klass)
          unless enabled? && klass.respond_to?(:get_sidekiq_options)
            return Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { yield }
          end

          store_name = klass.get_sidekiq_options['store']
          redis_name, shard_redis_pool = get_shard_instance(store_name)

          Gitlab::ApplicationContext.with_context(sidekiq_destination_shard_redis: redis_name) do
            Sidekiq::Client.via(shard_redis_pool) do
              yield
            end
          end
        end

        def with_routed_client
          Gitlab::Redis::Queues.instances.each_value do |inst|
            Sidekiq::Client.via(inst.sidekiq_redis) do
              yield
            end
          end
        end

        def migrated_shards
          @migrated_shards ||= Set.new(Gitlab::Json.parse(ENV.fetch('SIDEKIQ_MIGRATED_SHARDS', '[]')))
        end

        private

        def route_to(shard_name)
          # early return if main since we do not want a redundant feature flag check
          return shard_name if shard_name == Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME
          return shard_name if migrated_shards.include?(shard_name)

          if shard_name.nil? ||
              Feature.disabled?(:"sidekiq_route_to_#{shard_name}", type: :worker, default_enabled_if_undefined: false)
            # NOTE: this only works when splitting shard out from the main shard
            # An example where this does not work is if a queue `A` in a shard with 2 queue (A and B)
            # needs to be migrated to a new shard.
            return Gitlab::Redis::Queues::SIDEKIQ_MAIN_SHARD_INSTANCE_NAME
          end

          shard_name
        end
      end
    end
  end
end
