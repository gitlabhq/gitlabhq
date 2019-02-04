# frozen_string_literal: true

module Gitlab
  module WebIdeCommitsCounter
    WEB_IDE_COMMITS_KEY = "WEB_IDE_COMMITS_COUNT".freeze

    class << self
      def increment
        Gitlab::Redis::SharedState.with { |redis| redis.incr(WEB_IDE_COMMITS_KEY) }
      end

      def total_count
        Gitlab::Redis::SharedState.with { |redis| redis.get(WEB_IDE_COMMITS_KEY).to_i }
      end
    end
  end
end
