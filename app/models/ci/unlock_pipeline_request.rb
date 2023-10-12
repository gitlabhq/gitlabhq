# frozen_string_literal: true

module Ci
  class UnlockPipelineRequest
    QUEUE_REDIS_KEY = 'ci_unlock_pipeline_requests:queue'

    def self.enqueue(pipeline_id)
      unix_timestamp = Time.current.utc.to_i
      pipeline_ids = Array(pipeline_id).uniq
      pipeline_ids_with_scores = pipeline_ids.map do |id|
        # The order of values per pair is `[score, key]`, so in this case, the unix timestamp is the score.
        # By default, the sort order of sorted sets is from lowest to highest, though this does not matter much
        # because we use `ZPOPMIN` to make sure to return the lowest/oldest request in terms of unix timestamp score.
        [unix_timestamp, id]
      end

      with_redis do |redis|
        added = redis.zadd(QUEUE_REDIS_KEY, pipeline_ids_with_scores, nx: true)
        log_event(:enqueued, pipeline_ids) if added > 0
        added
      end
    end

    def self.next!
      with_redis do |redis|
        pipeline_id, enqueue_timestamp = redis.zpopmin(QUEUE_REDIS_KEY)
        break unless pipeline_id

        pipeline_id = pipeline_id.to_i
        log_event(:picked_next, pipeline_id)

        [pipeline_id, enqueue_timestamp.to_i]
      end
    end

    def self.total_pending
      with_redis do |redis|
        redis.zcard(QUEUE_REDIS_KEY)
      end
    end

    def self.with_redis(&block)
      Gitlab::Redis::SharedState.with(&block)
    end

    def self.log_event(event, pipeline_id)
      Gitlab::AppLogger.info(
        message: "Pipeline unlock - #{event}",
        pipeline_id: pipeline_id
      )
    end
  end
end
