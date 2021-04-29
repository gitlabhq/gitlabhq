# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class DestroyAllExpiredService
      include ::Gitlab::LoopHelpers
      include ::Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 100
      LOOP_TIMEOUT = 5.minutes
      LOOP_LIMIT = 1000

      def initialize
        @removed_artifacts_count = 0
      end

      def execute
        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
          destroy_artifacts_batch
        end

        @removed_artifacts_count
      end

      private

      def destroy_artifacts_batch
        artifacts = ::Ci::PipelineArtifact.unlocked.expired(BATCH_SIZE).to_a
        return false if artifacts.empty?

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
