# frozen_string_literal: true

module Gitlab
  module Cleanup
    module Redis
      class BatchDeleteByPattern
        REDIS_CLEAR_BATCH_SIZE = 1000 # There seems to be no speedup when pushing beyond 1,000
        REDIS_SCAN_START_STOP = '0'.freeze # Magic value, see http://redis.io/commands/scan

        attr_reader :patterns

        def initialize(patterns)
          raise ArgumentError.new('Argument should be an Array of patterns') unless patterns.is_a?(Array)

          @patterns = patterns
        end

        def execute
          return if patterns.blank?

          batch_delete_cache_keys
        end

        private

        def batch_delete_cache_keys
          Gitlab::Redis::Cache.with do |redis|
            patterns.each do |match|
              cursor = REDIS_SCAN_START_STOP
              loop do
                cursor, keys = redis.scan(
                  cursor,
                  match: match,
                  count: REDIS_CLEAR_BATCH_SIZE
                )

                Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
                  redis.del(*keys) if keys.any?
                end

                break if cursor == REDIS_SCAN_START_STOP
              end
            end
          end
        end
      end
    end
  end
end
