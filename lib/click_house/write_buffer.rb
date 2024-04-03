# frozen_string_literal: true

module ClickHouse
  module WriteBuffer
    BUFFER_KEY = 'clickhouse_write_buffer'

    class << self
      def write_event(event_hash)
        Gitlab::Redis::SharedState.with do |redis|
          redis.lpush(BUFFER_KEY, event_hash.to_json)
        end
      end
    end
  end
end
