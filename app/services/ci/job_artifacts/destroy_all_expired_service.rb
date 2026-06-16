# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyAllExpiredService
      include ::Gitlab::LoopHelpers

      BATCH_SIZE = 100
      LOOP_LIMIT = 500
      LOOP_TIMEOUT = 5.minutes

      Result = Struct.new(
        :destroyed_count,
        :more_work_likely,
        :drain_loops,
        :partitions_exhausted,
        :exited_early,
        keyword_init: true
      )

      def initialize(mod_bucket:, max_buckets:)
        @mod_bucket = mod_bucket
        @max_buckets = max_buckets
        @destroyed_count = 0
        @drain_loops = 0
        @partitions_exhausted = 0
        @exited_early = false
      end

      ##
      # Destroys expired job artifacts for the given mod_bucket by iterating
      # over physical partition groups of `p_ci_job_artifacts`. Each query is
      # scoped to a single partition group so PostgreSQL can prune partitions.
      def execute
        partitions = Ci::JobArtifact.partition_groups

        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
          if partitions.empty?
            @exited_early = true
            break
          end

          destroyed = drain(partitions.first)
          if destroyed == 0
            partitions.shift
            @partitions_exhausted += 1
          else
            @destroyed_count += destroyed
            @drain_loops += 1
          end
        end

        Result.new(
          destroyed_count: @destroyed_count,
          more_work_likely: @destroyed_count > BATCH_SIZE,
          drain_loops: @drain_loops,
          partitions_exhausted: @partitions_exhausted,
          exited_early: @exited_early
        )
      end

      private

      def drain(partition_ids)
        relation = Ci::JobArtifact
          .expired_and_deletable
          .in_partition(partition_ids)
          .for_mod_bucket(@mod_bucket, @max_buckets)
          .limit(BATCH_SIZE)

        Ci::JobArtifacts::DestroyBatchService
          .new(relation, skip_projects_on_refresh: true)
          .execute
          .fetch(:destroyed_artifacts_count)
      end
    end
  end
end
