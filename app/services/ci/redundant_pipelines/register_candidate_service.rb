# frozen_string_literal: true

module Ci
  module RedundantPipelines
    # Stores a pipeline in the cache, so a newer pipeline on the same project and
    # ref can find it without searching p_ci_pipelines.
    class RegisterCandidateService
      NOT_CANCELABLE = {
        message: 'Pipeline is not cancelable by a newer pipeline',
        reason: :pipeline_not_cancelable_by_newer_pipeline
      }.freeze

      def self.for(pipeline)
        policy = Gitlab::Ci::RedundantPipelines::AutoCancelPolicy.new(pipeline)
        cache = Gitlab::Ci::RedundantPipelines::CandidateCache.for(
          project_id: pipeline.project_id, ref: pipeline.ref
        )

        new(pipeline, policy: policy, cache: cache)
      end

      def initialize(pipeline, policy:, cache:)
        @pipeline = pipeline
        @policy = policy
        @cache = cache
      end

      def execute
        return ServiceResponse.error(**NOT_CANCELABLE) unless policy.cancelable_by_newer_pipeline?

        key = Gitlab::Ci::RedundantPipelines::PipelineKey.of(pipeline)

        cache.register(key)

        ServiceResponse.success
      end

      private

      attr_reader :pipeline, :policy, :cache
    end
  end
end
