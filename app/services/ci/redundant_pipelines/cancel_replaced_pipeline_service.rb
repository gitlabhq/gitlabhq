# frozen_string_literal: true

module Ci
  module RedundantPipelines
    # Cancels an older pipeline taken from the cache when this pipeline replaces it.
    class CancelReplacedPipelineService
      include Gitlab::Utils::StrongMemoize

      REQUEUED = {
        message: 'This pipeline does not replace the older pipeline, so it goes back in the cache',
        reason: :pipeline_requeued
      }.freeze

      DROPPED = {
        message: 'The older pipeline is gone or finished, so it stays out of the cache',
        reason: :pipeline_dropped
      }.freeze

      def self.for(key, superseded_by:, ref_head_sha: nil)
        new(
          key,
          superseded_by: superseded_by,
          ref_head_sha: ref_head_sha,
          cache: Gitlab::Ci::RedundantPipelines::CandidateCache.for(
            project_id: superseded_by.project_id, ref: superseded_by.ref
          )
        )
      end

      def initialize(key, superseded_by:, cache:, ref_head_sha: nil)
        @key = key
        @superseded_by = superseded_by
        @ref_head_sha = ref_head_sha
        @cache = cache
      end

      def execute
        return ServiceResponse.error(**DROPPED) unless older_pipeline.present? && family.active?
        return requeue unless superseded?

        family.cancel(auto_canceled_by: superseded_by)

        ServiceResponse.success
      end

      private

      attr_reader :key, :superseded_by, :ref_head_sha, :cache

      def older_pipeline
        Ci::Pipeline.find_by_id_and_partition(key.pipeline_id, key.partition_id)
      end
      strong_memoize_attr :older_pipeline

      def family
        Gitlab::Ci::RedundantPipelines::PipelineFamily.new(older_pipeline)
      end
      strong_memoize_attr :family

      # A force push back can make a later pipeline run an earlier commit, so the
      # ref's current commit is never canceled.
      def superseded?
        !older_pipeline.sha.in?([superseded_by.sha, ref_head_sha]) &&
          older_pipeline.created_at < superseded_by.created_at
      end

      def requeue
        cache.register(key)

        ServiceResponse.error(**REQUEUED)
      end
    end
  end
end
