# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class AtomicProcessingService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      attr_reader :pipeline

      DEFAULT_LEASE_TIMEOUT = 1.minute
      BATCH_SIZE = 20

      def initialize(pipeline)
        @pipeline = pipeline
        @collection = AtomicProcessingService::StatusCollection.new(pipeline)
      end

      def execute
        return unless pipeline.needs_processing?

        # Run the process only if we can obtain an exclusive lease; returns nil if lease is unavailable
        success = try_obtain_lease { process! }

        # Re-schedule if we need further processing
        if success && pipeline.needs_processing?
          PipelineProcessWorker.perform_async(pipeline.id)
        end

        success
      end

      private

      def process!
        update_stages!
        update_pipeline!
        update_jobs_processed!

        Ci::ExpirePipelineCacheService.new.execute(pipeline)

        true
      end

      def update_stages!
        pipeline.stages.ordered.each { |stage| update_stage!(stage) }
      end

      def update_stage!(stage)
        # Update jobs for a given stage in bulk/slices
        @collection
          .created_job_ids_in_stage(stage.position)
          .in_groups_of(BATCH_SIZE, false) { |ids| update_jobs!(ids) }

        status = @collection.status_of_stage(stage.position)
        stage.set_status(status)
      end

      def update_jobs!(ids)
        created_jobs = pipeline
          .current_processable_jobs
          .id_in(ids)
          .with_project_preload
          .created
          .ordered_by_stage
          .select_with_aggregated_needs(project)

        created_jobs.each { |job| update_job!(job) }
      end

      def update_pipeline!
        pipeline.set_status(@collection.status_of_all)
      end

      def update_jobs_processed!
        processing = @collection.processing_jobs
        processing.each_slice(BATCH_SIZE) do |slice|
          pipeline.all_jobs.match_id_and_lock_version(slice)
            .update_as_processed!
        end
      end

      def update_job!(job)
        previous_status = status_of_previous_jobs(job)
        # We do not continue to process the job if the previous status is not completed
        return unless Ci::HasStatus::COMPLETED_STATUSES.include?(previous_status)

        Gitlab::OptimisticLocking.retry_lock(job, name: 'atomic_processing_update_job') do |subject|
          Ci::ProcessBuildService.new(project, subject.user)
            .execute(subject, previous_status)

          # update internal representation of job
          # to make the status change of job to be taken into account during further processing
          @collection.set_job_status(job.id, job.status, job.lock_version)
        end
      end

      def status_of_previous_jobs(job)
        if job.scheduling_type_dag?
          # job uses DAG, get status of all dependent needs
          @collection.status_of_jobs(job.aggregated_needs_names.to_a)
        else
          # job uses Stages, get status of prior stage
          @collection.status_of_jobs_prior_to_stage(job.stage_idx.to_i)
        end
      end

      def project
        pipeline.project
      end

      def lease_key
        "#{super}::pipeline_id:#{pipeline.id}"
      end

      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
