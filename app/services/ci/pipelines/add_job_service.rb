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

        in_lock("ci:pipelines:#{pipeline.id}:add-job", ttl: LOCK_TIMEOUT, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRIES) do
          Ci::Pipeline.transaction do
            yield(job)

            job.update_older_statuses_retried!
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
        job.partition_id = pipeline.partition_id

        # update metadata since it might have been lazily initialised before this call
        # metadata is present on `Ci::Processable`
        if job.respond_to?(:metadata) && job.metadata
          job.metadata.project = pipeline.project
          job.metadata.partition_id = pipeline.partition_id
        end
      end
    end
  end
end
