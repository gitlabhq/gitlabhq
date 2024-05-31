# frozen_string_literal: true

# This module references https://github.com/redis-rb/redis-client#instrumentation-and-middlewares
# implementing `call`, and `call_pipelined`.
module Gitlab
  module Instrumentation
    module RedisClientMiddleware
      include RedisHelper

      def call(command, redis_config)
        instrumentation = instrumentation_class(redis_config)

        result = instrument_call([command], instrumentation) do
          super
        end

        measure_io(command, result, instrumentation) if ::RequestStore.active?

        result
      end

      def call_pipelined(commands, redis_config)
        instrumentation = instrumentation_class(redis_config)

        result = instrument_call(commands, instrumentation, true) do
          super
        end

        measure_io(commands, result, instrumentation) if ::RequestStore.active?

        result
      end

      private

      def measure_io(command, result, instrumentation)
        measure_write_size(command, instrumentation)
        measure_read_size(result, instrumentation)
      end

      def instrumentation_class(config)
        ::Gitlab::Instrumentation::Redis.storage_hash[config.custom[:instrumentation_class]]
      end
    end
  end
end
