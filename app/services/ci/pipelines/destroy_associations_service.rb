# frozen_string_literal: true

module Ci
  module Pipelines
    # Orchestrates job artifact destruction for a pipeline using two-level
    # batching (builds -> artifacts) to avoid statement timeouts.
    #
    # The standard `pipeline.job_artifacts` (`has_many :through :builds`)
    # generates a JOIN query where `each_batch`'s `ORDER BY id LIMIT 1`
    # tricks the planner into scanning via the primary key index instead of
    # `p_ci_builds_commit_id_status_type_idx`, causing timeouts on pipelines
    # with many builds.
    #
    # This service uses `Pipeline#builds_with_cte` to force the correct index
    # via a materialized CTE, then iterates builds in batches and destroys
    # artifacts per batch using the existing DestroyAssociationsService.
    #
    # A single Ci::JobArtifacts::DestroyAssociationsService instance
    # accumulates statistics across all build batches so that
    # `finalize_fast_destroy` can be called once with a single service object.
    #
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/582836
    class DestroyAssociationsService
      BUILDS_BATCH_SIZE = 100

      def initialize(pipeline)
        @pipeline = pipeline
        @artifacts_destroy_service = Ci::JobArtifacts::DestroyAssociationsService.new
      end

      # rubocop: disable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit -- builds are already batched
      def destroy_records
        @pipeline.builds_with_cte.each_batch(of: BUILDS_BATCH_SIZE) do |builds|
          artifacts = Ci::JobArtifact.where(job_id: builds.pluck(:id), partition_id: @pipeline.partition_id)
          @artifacts_destroy_service.destroy_records(artifacts)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit

      def update_statistics
        @artifacts_destroy_service.update_statistics
      end
    end
  end
end
