# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class DestroyAllExpiredService
      include ::Gitlab::ExclusiveLeaseHelpers
      include ::Gitlab::LoopHelpers
      include ::Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 100
      LOOP_LIMIT = 1000
      LOOP_TIMEOUT = 5.minutes
      LOCK_TIMEOUT = 10.minutes
      EXCLUSIVE_LOCK_KEY = 'expired_pipeline_artifacts:destroy:lock'

      def initialize
        @removed_artifacts_count = 0
        @start_at = Time.current
      end

      def execute
        in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
          destroy_unlocked_pipeline_artifacts
        end

        @removed_artifacts_count
      end

      private

      def destroy_unlocked_pipeline_artifacts
        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
          artifacts = Ci::PipelineArtifact.expired_before(@start_at).artifact_unlocked.limit(BATCH_SIZE)

          break if artifacts.empty?

          destroy_batch(artifacts)
        end
      end

      def destroy_batch(artifacts)
        artifacts.each(&:destroy!)
        increment_stats(artifacts.size)

        true
      end

      def increment_stats(size)
        destroyed_artifacts_counter.increment({}, size)
        @removed_artifacts_count += size
      end

      def destroyed_artifacts_counter
        strong_memoize(:destroyed_artifacts_counter) do
          name = :destroyed_pipeline_artifacts_count_total
          comment = 'Counter of destroyed expired pipeline artifacts'

          ::Gitlab::Metrics.counter(name, comment)
        end
      end
    end
  end
end
