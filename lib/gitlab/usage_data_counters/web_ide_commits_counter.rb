# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class WebIdeCommitsCounter
      extend RedisCounter

      def self.redis_counter_key
        'WEB_IDE_COMMITS_COUNT'
      end
    end
  end
end
