# frozen_string_literal: true

module Ci
  module Pipelines
    class AddJobService
      include ::Gitlab::ExclusiveLeaseHelpers

      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline

        raise ArgumentError, "Pipeline must be persisted for this service to be used" unless pipeline.persisted?
      end

      def execute!(job, &block)
        assign_pipeline_attributes(job)

        if Feature.enabled?(:ci_pipeline_add_job_with_lock, pipeline.project, default_enabled: :yaml)
          in_lock("ci:pipelines:#{pipeline.id}:add-job", ttl: LOCK_TIMEOUT, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRIES) do
            Ci::Pipeline.transaction do
              yield(job)

              job.update_older_statuses_retried! if Feature.enabled?(:ci_fix_commit_status_retried, pipeline.project, default_enabled: :yaml)
            end
          end
        else
          Ci::Pipeline.transaction do
            yield(job)

            job.update_older_statuses_retried! if Feature.enabled?(:ci_fix_commit_status_retried, pipeline.project, default_enabled: :yaml)
          end
        end

        ServiceResponse.success(payload: { job: job })
      rescue StandardError => e
        ServiceResponse.error(message: e.message, payload: { job: job })
      end

      private

      LOCK_TIMEOUT = 1.minute
      LOCK_SLEEP = 0.5.seconds
      LOCK_RETRIES = 20

      def assign_pipeline_attributes(job)
        job.pipeline = pipeline
        job.project = pipeline.project
        job.ref = pipeline.ref
      end
    end
  end
end
