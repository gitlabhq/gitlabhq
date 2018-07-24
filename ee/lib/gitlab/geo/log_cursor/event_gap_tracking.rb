module Gitlab
  module Geo
    module LogCursor
      class EventGapTracking
        include Utils::StrongMemoize

        attr_reader :log_level
        attr_accessor :previous_id

        GEO_LOG_CURSOR_GAPS = "Gitlab::Geo::LogCursor::Gaps".freeze
        GAP_GRACE_PERIOD = 10.minutes
        GAP_OUTDATED_PERIOD = 1.hour

        def initialize(log_level = Rails.logger.level)
          @log_level = log_level
          @previous_id = 0
        end

        def check!(current_id)
          return unless previous_id > 0

          return unless gap?(current_id)

          track_gap(current_id)
        ensure
          self.previous_id = current_id
        end

        # accepts a block that should return whether the event was handled
        def fill_gaps
          with_redis do |redis|
            redis.zremrangebyscore(GEO_LOG_CURSOR_GAPS, '-inf', outdated_timestamp)

            gap_ids = redis.zrangebyscore(GEO_LOG_CURSOR_GAPS, '-inf', grace_timestamp, with_scores: true)

            gap_ids.each do |event_id, score|
              handled = yield event_id.to_i

              redis.zrem(GEO_LOG_CURSOR_GAPS, event_id) if handled
            end
          end
        end

        def track_gap(current_id)
          logger.info("Event log gap detected", previous_event_id: previous_id, current_event_id: current_id)

          with_redis do |redis|
            expire_time = Time.now.to_i

            ((previous_id + 1)..(current_id - 1)).each do |gap_id|
              redis.zadd(GEO_LOG_CURSOR_GAPS, expire_time, gap_id)
            end
          end
        end

        def gap?(current_id)
          return false if previous_id <= 0

          current_id > (previous_id + 1)
        end

        private

        def logger
          strong_memoize(:logger) do
            Gitlab::Geo::LogCursor::Logger.new(self.class, log_level)
          end
        end

        def with_redis
          ::Gitlab::Redis::Cache.with { |redis| yield redis }
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
end
