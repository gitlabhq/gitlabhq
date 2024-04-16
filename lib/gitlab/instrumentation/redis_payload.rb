# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module RedisPayload
      include ::Gitlab::Utils::StrongMemoize

      def payload
        to_lazy_payload.transform_values do |value|
          result = value.call
          result if result > 0
        end.compact
      end

      private

      def to_lazy_payload
        strong_memoize(:to_lazy_payload) do
          key_prefix = storage_key ? "redis_#{storage_key}" : 'redis'
          key_prefix += "_#{shard_key}" if shard_key && shard_key != RedisBase::DEFAULT_SHARD_KEY

          {
            "#{key_prefix}_calls": -> { get_request_count },
            "#{key_prefix}_cross_slot_calls": -> { get_cross_slot_request_count },
            "#{key_prefix}_allowed_cross_slot_calls": -> { get_allowed_cross_slot_request_count },
            "#{key_prefix}_duration_s": -> { query_time },
            "#{key_prefix}_read_bytes": -> { read_bytes },
            "#{key_prefix}_write_bytes": -> { write_bytes }
          }.symbolize_keys
        end
      end
    end
  end
end
