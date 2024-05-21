# frozen_string_literal: true

module ClickHouse
  module WriteBuffer
    BUFFER_KEY = 'clickhouse_write_buffer'

    class << self
      # Currently scoped to code suggestion events only
      def write_event(event_hash)
        Gitlab::Redis::SharedState.with do |redis|
          redis.rpush(BUFFER_KEY, event_hash.to_json)
        end
      end

      def pop_events(limit)
        Gitlab::Redis::SharedState.with do |redis|
          Array.wrap(redis.lpop(BUFFER_KEY, limit)).map do |hash|
            Gitlab::Json.parse(hash, symbolize_names: true)
          end
        end
      end
    end
  end
end
