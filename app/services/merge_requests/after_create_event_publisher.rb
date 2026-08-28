# frozen_string_literal: true

module MergeRequests
  # Publishes MergeRequests::AfterCreateCloudEvent for a newly-created merge request from
  # the create-time mergeability check: that check is what syncs code-owner approval
  # rules against the built diff, and consumers need both.
  class AfterCreateEventPublisher
    # Only bounds the leak when the mergeability check never runs at all. Generous on
    # purpose: if the check chain backs up, firing late beats never firing.
    TTL = 1.hour

    def initialize(merge_request)
      @merge_request = merge_request
    end

    # Call before the mergeability check is scheduled: the check can reach
    # #publish_deferred within a few hundred milliseconds, well before the rest of the
    # after-create work finishes, and would otherwise find nothing to publish.
    def defer_to_mergeability_check
      return unless enabled?

      Gitlab::Redis::SharedState.with do |redis|
        redis.set(redis_key, 1, ex: TTL.to_i, nx: true)
      end
    end

    def publish_deferred
      return unless enabled?

      # The flag is set moments before `prepared_at`, so anything older than the TTL
      # cannot hold one. Nil means the check beat the rest of the create.
      return if merge_request.prepared_at&.before?(TTL.ago)
      return unless consume

      Gitlab::EventStore.publish(
        AfterCreateCloudEvent.build(merge_request: merge_request, current_user: merge_request.author)
      )
    end

    private

    attr_reader :merge_request

    def enabled?
      Feature.enabled?(:merge_request_create_flow_trigger, merge_request.project)
    end

    def consume
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(redis_key) == 1
      end
    end

    def redis_key
      "merge_requests:pending_after_create_publish:#{merge_request.id}"
    end
  end
end
