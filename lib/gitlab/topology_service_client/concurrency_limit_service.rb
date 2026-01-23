# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    # This service manages a GLOBAL concurrency limit for the Topology Service.
    # At any moment in time, there should not be more than the configured limit
    # of concurrent requests to the Topology Service. This is a cell-wide limit
    # that applies to ALL requests, regardless of source or type.
    #
    # Uses a Redis Hash to track individual requests by process ID and request ID,
    # similar to Sidekiq's WorkerExecutionTracker. This approach prevents counter
    # drift when requests fail without proper cleanup.
    #
    # Configuration:
    # - ApplicationSettings stores the limit value (topology_service_concurrency_limit)
    # - Feature flag controls enforcement mode (log-only vs enforce)
    class ConcurrencyLimitService
      REDIS_KEY_EXECUTING = 'topology_service:concurrency_limit:executing'
      TRACKING_KEY_TTL = 5.minutes

      # Lua script for atomically checking the concurrency limit and adding a request.
      # Returns 1 if the request was added (limit not exceeded), 0 if rejected.
      # Uses Redis server time for consistency with cleanup operations.
      # KEYS[1]: REDIS_KEY_EXECUTING (hash key)
      # ARGV[1]: request_id
      # ARGV[2]: concurrency_limit
      CHECK_AND_ADD_REQUEST_SCRIPT = <<~LUA
        local key, request_id, limit = KEYS[1], ARGV[1], tonumber(ARGV[2])
        local current_time = redis.call("TIME")[1]
        local current_count = redis.call("hlen", key)
        if current_count >= limit then
          return 0
        end
        redis.call("hset", key, request_id, current_time)
        return 1
      LUA

      class << self
        # Get current concurrency limit from ApplicationSettings
        # @return [Integer] The current limit
        def concurrency_limit
          Gitlab::CurrentSettings.topology_service_concurrency_limit
        end

        # @return [Boolean] true if enforce mode is enabled
        def enforce_mode_enabled?
          Feature.enabled?(:topology_service_concurrency_limit, :instance, type: :ops)
        end

        # @return [Integer] The current concurrent request count
        def concurrent_request_count
          with_redis_suppressed_errors { |r| r.hlen(REDIS_KEY_EXECUTING) }.to_i
        end

        # Track request start by atomically checking the limit and adding an entry to the hash.
        # Uses a Lua script to ensure the check and increment are atomic, preventing race conditions.
        # @param grpc_method [String] The gRPC method being called (e.g., '/TopologyService/GetCell')
        # @return [String, nil] The unique request ID if limit not exceeded, nil if rejected
        def track_request_start(grpc_method: nil)
          request_id = generate_request_id(grpc_method)

          result = with_redis_suppressed_errors do |r|
            r.eval(
              CHECK_AND_ADD_REQUEST_SCRIPT,
              keys: [REDIS_KEY_EXECUTING],
              argv: [request_id, concurrency_limit]
            )
          end

          return request_id if result.nil? # Redis failure case, allow request

          result == 1 ? request_id : nil
        end

        # Track request end by removing the entry from the hash
        # @param request_id [String] The request ID returned by track_request_start
        def track_request_end(request_id)
          return if request_id.nil?

          with_redis_suppressed_errors do |r|
            r.hdel(REDIS_KEY_EXECUTING, request_id)
          end
        end

        # Clean up stale request entries that are older than TTL
        # Called by StaleRequestsCleanupCronWorker on a schedule
        # @return [Hash, nil] Hash with :removed_count on success, nil if Redis unavailable
        def cleanup_stale_requests
          cutoff_time = TRACKING_KEY_TTL.ago.utc.to_i
          removed_count = 0

          with_redis_suppressed_errors do |r|
            stale_requests = r.hgetall(REDIS_KEY_EXECUTING)
                              .select { |_id, started_at| started_at.to_i < cutoff_time }
            next if stale_requests.empty?

            removed_count = r.hdel(REDIS_KEY_EXECUTING, stale_requests.keys)
          end
          { removed_count: removed_count }
        end

        def extract_method_name(grpc_method, fallback: 'unknown')
          return fallback if grpc_method.blank?

          grpc_method.rpartition('/').last.presence || fallback
        end

        private

        def generate_request_id(grpc_method)
          # Combine process ID, gRPC method, correlation ID, and a unique suffix
          # Format: "pid:method:correlationId:hex" (e.g., "12345:GetCell:abc-123-def:a1b2c3d4e5f6g7h8")
          # The UUID suffix ensures uniqueness even when correlation ID, which can happen
          # if a same request ends up making multiple requests to TS.
          method_name = extract_method_name(grpc_method)
          correlation_id = Labkit::Correlation::CorrelationId.current_id
          "#{Process.pid}:#{method_name}:#{correlation_id}:#{SecureRandom.hex(8)}"
        end

        def with_redis_suppressed_errors(&block)
          Gitlab::Redis::RateLimiting.with_suppressed_errors(&block)
        end
      end
    end
  end
end
