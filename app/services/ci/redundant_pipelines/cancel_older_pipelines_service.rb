# frozen_string_literal: true

module Ci
  module RedundantPipelines
    # Cancels the older pipelines on this ref that this pipeline replaces, taken from
    # the cache instead of searched in p_ci_pipelines.
    class CancelOlderPipelinesService
      include Gitlab::Utils::StrongMemoize

      DOES_NOT_APPLY = {
        message: 'Auto-cancellation does not apply to this pipeline',
        reason: :auto_cancel_does_not_apply
      }.freeze

      def self.for(pipeline)
        new(
          pipeline,
          policy: Gitlab::Ci::RedundantPipelines::AutoCancelPolicy.new(pipeline),
          cache: Gitlab::Ci::RedundantPipelines::CandidateCache.for(
            project_id: pipeline.project_id, ref: pipeline.ref
          )
        )
      end

      def initialize(pipeline, policy:, cache:)
        @pipeline = pipeline
        @policy = policy
        @cache = cache
      end

      def execute
        return ServiceResponse.error(**DOES_NOT_APPLY) unless policy.applies?

        canceled_count = older_pipelines.count { |key| cancel_replaced(key) }

        ServiceResponse.success(payload: { canceled_count: canceled_count })
      end

      private

      attr_reader :pipeline, :policy, :cache

      def older_pipelines
        cache.claim_before(Gitlab::Ci::RedundantPipelines::PipelineKey.of(pipeline))
      end

      def cancel_replaced(key)
        CancelReplacedPipelineService
          .new(key, superseded_by: pipeline, ref_head_sha: ref_head_sha, cache: cache)
          .execute
          .success?
      end

      def ref_head_sha
        pipeline.project.commit(pipeline.ref)&.id
      end
      strong_memoize_attr :ref_head_sha
    end
  end
end
