module Gitlab
  module Geo
    class EventGapTracking
      include Utils::StrongMemoize
      include ::Gitlab::Geo::LogHelpers

      attr_accessor :previous_id

      GEO_EVENT_LOG_GAPS = 'geo:event_log:gaps'.freeze
      GAP_GRACE_PERIOD = 10.minutes
      GAP_OUTDATED_PERIOD = 1.hour

      class << self
        def min_gap_id
          with_redis do |redis|
            redis.zrange(GEO_EVENT_LOG_GAPS, 0, -1).min&.to_i
          end
        end

        def gap_count
          with_redis do |redis|
            redis.zcount(GEO_EVENT_LOG_GAPS, '-inf', '+inf')
          end
        end

        def with_redis
          ::Gitlab::Redis::SharedState.with { |redis| yield redis }
        end
      end

      delegate :with_redis, to: :class

      def initialize(logger = ::Gitlab::Geo::Logger)
        @logger = logger
        @previous_id = 0
      end

      def check!(current_id)
        return unless previous_id > 0

        return unless gap?(current_id)

        track_gaps(current_id)
      ensure
        self.previous_id = current_id
      end

      # accepts a block that should return whether the event was handled
      def fill_gaps
        with_redis do |redis|
          redis.zremrangebyscore(GEO_EVENT_LOG_GAPS, '-inf', outdated_timestamp)

          gap_ids = redis.zrangebyscore(GEO_EVENT_LOG_GAPS, '-inf', grace_timestamp).map(&:to_i)
          break if gap_ids.empty?

          ::Geo::EventLog.where(id: gap_ids).each_batch do |batch|
            batch.includes_events.each { |event_log| yield event_log }
            redis.zrem(GEO_EVENT_LOG_GAPS, batch.map(&:id))
          end
        end
      end

      private

      def track_gaps(current_id)
        log_info("Event log gap detected", previous_event_id: previous_id, current_event_id: current_id)

        with_redis do |redis|
          expire_time = Time.now.to_i

          ((previous_id + 1)..(current_id - 1)).each do |gap_id|
            redis.zadd(GEO_EVENT_LOG_GAPS, expire_time, gap_id)
          end
        end
      end

      def gap?(current_id)
        return false if previous_id <= 0

        current_id > (previous_id + 1)
      end

      def grace_timestamp
        (Time.now - GAP_GRACE_PERIOD).to_i
      end

      def outdated_timestamp
        (Time.now - GAP_OUTDATED_PERIOD).to_i
      end
    end
  end
end
