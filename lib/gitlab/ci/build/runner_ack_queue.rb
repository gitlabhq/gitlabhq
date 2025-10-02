# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class RunnerAckQueue
        # The `RUNNER_ACK_QUEUE_EXPIRY_TIME` indicates the longest interval that GitLab will wait for a ping from
        #   a Runner supporting 2-phase commit to either continue waiting (status=pending) or accept (status=running) a
        #   job that is pending for that runner.
        RUNNER_ACK_QUEUE_EXPIRY_TIME = 2.minutes

        def initialize(build)
          @build = build
        end

        # Create a Redis cache entry containing the runner manager id on which we're waiting on
        # for acknowledgement (job accepted or job declined)
        def set_waiting_for_runner_ack(runner_manager_id)
          return unless runner_manager_id.present?

          with_redis do |redis|
            # Store runner manager ID for this job, only if key does not yet exist
            redis.set(redis_key, runner_manager_id, ex: RUNNER_ACK_QUEUE_EXPIRY_TIME, nx: true)
          end
        end

        # Update the ttl for the Redis cache entry containing the runner manager id on which we're waiting on
        # for acknowledgement (job accepted or job declined)
        def heartbeat_runner_ack_wait(runner_manager_id)
          return unless runner_manager_id.present? && runner_manager_id == runner_manager_id_waiting_for_ack

          with_redis do |redis|
            # Update TTL, only if key already exists
            redis.set(redis_key, runner_manager_id, ex: RUNNER_ACK_QUEUE_EXPIRY_TIME, xx: true)
          end
        end

        # Remove the Redis cache entry containing the runner manager id on which we're waiting on
        # for acknowledgement (job accepted or job declined)
        def cancel_wait_for_runner_ack
          with_redis do |redis|
            redis.del(redis_key)
          end
        end

        def runner_manager_id_waiting_for_ack
          with_redis { |redis| redis.get(redis_key)&.to_i }
        end

        def redis_key
          "runner:build_ack_queue:#{build.id}"
        end

        private

        attr_reader :build

        def with_redis(&block)
          # Use SharedState to avoid cache evictions
          ::Gitlab::Redis::SharedState.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- This is not AR
        end
      end
    end
  end
end
