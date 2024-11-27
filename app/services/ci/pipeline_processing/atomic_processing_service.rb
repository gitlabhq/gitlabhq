# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class AtomicProcessingService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      attr_reader :pipeline, :collection

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

        if success
          # If any jobs changed from stopped to alive status during pipeline processing, we must
          # re-reset their dependent jobs; see https://gitlab.com/gitlab-org/gitlab/-/issues/388539.
          new_alive_jobs.group_by(&:user).each do |user, jobs|
            log_running_reset_skipped_jobs_service(jobs)

            ResetSkippedJobsService.new(project, user).execute(jobs)
          end

          # Re-schedule if we need further processing
          PipelineProcessWorker.perform_async(pipeline.id) if pipeline.needs_processing?
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
        sorted_update_stage!(stage)
        status = @collection.status_of_stage(stage.position)
        stage.set_status(status)
      end

      def sorted_update_stage!(stage)
        ordered_jobs(stage).each { |job| update_job!(job) }
      end

      def ordered_jobs(stage)
        jobs = load_jobs_in_batches(stage)
        sorted_job_names = sort_jobs(jobs).each_with_index.to_h
        jobs.sort_by { |job| sorted_job_names.fetch(job.name) }
      end

      def load_jobs_in_batches(stage)
        @collection
          .created_job_ids_in_stage(stage.position)
          .in_groups_of(BATCH_SIZE, false)
          .each_with_object([]) do |ids, jobs|
            jobs.concat(load_jobs(ids))
          end
      end

      def load_jobs(ids)
        pipeline
          .current_processable_jobs
          .id_in(ids)
          .with_project_preload
          .created
          .ordered_by_stage
          .select_with_aggregated_needs(project)
      end

      def sort_jobs(jobs)
        Gitlab::Ci::YamlProcessor::Dag.order( # rubocop: disable CodeReuse/ActiveRecord -- this is not ActiveRecord
          jobs.to_h do |job|
            [job.name, job.aggregated_needs_names.to_a]
          end
        )
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

        ::Deployments::CreateForJobService.new.execute(job)

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
          status_of_previous_jobs_dag(job)
        else
          # job uses Stages, get status of prior stage
          @collection.status_of_jobs_prior_to_stage(job.stage_idx.to_i)
        end
      end

      def status_of_previous_jobs_dag(job)
        # job uses DAG, get status of all dependent needs
        @collection.status_of_jobs(job.aggregated_needs_names.to_a)
      end

      # Gets the jobs that changed from stopped to alive status since the initial status collection
      # was evaluated. We determine this by checking if their current status is no longer stopped.
      def new_alive_jobs
        initial_stopped_job_names = @collection.stopped_job_names

        return [] if initial_stopped_job_names.empty?

        new_collection = AtomicProcessingService::StatusCollection.new(pipeline)
        new_alive_job_names = initial_stopped_job_names - new_collection.stopped_job_names

        return [] if new_alive_job_names.empty?

        pipeline
          .current_jobs
          .by_name(new_alive_job_names)
          .preload(:user) # rubocop: disable CodeReuse/ActiveRecord
          .to_a
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

      def lease_taken_log_level
        :info
      end

      def log_running_reset_skipped_jobs_service(jobs)
        Gitlab::AppJsonLogger.info(
          class: self.class.name.to_s,
          message: 'Running ResetSkippedJobsService on new alive jobs',
          project_id: project.id,
          pipeline_id: pipeline.id,
          user_id: jobs.first.user.id,
          jobs_count: jobs.count
        )
      end
    end
  end
end

Ci::PipelineProcessing::AtomicProcessingService.prepend_mod
