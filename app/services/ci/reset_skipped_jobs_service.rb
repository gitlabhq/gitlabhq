# frozen_string_literal: true

module Ci
  # This service resets skipped jobs so they can be processed again.
  # It affects the jobs that depend on the passed in job parameter.
  class ResetSkippedJobsService < ::BaseService
    def execute(processables)
      @processables = Array.wrap(processables)
      @pipeline = @processables.first.pipeline

      process_subsequent_jobs
      reset_source_bridge
    end

    private

    def process_subsequent_jobs
      dependent_jobs.each do |job|
        process(job)
      end
    end

    def reset_source_bridge
      @pipeline.reset_source_bridge!(current_user)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def dependent_jobs
      ordered_by_dag(
        @pipeline.processables
          .from_union(needs_dependent_jobs, stage_dependent_jobs)
          .skipped
          .ordered_by_stage
          .preload(:needs)
      )
    end

    def process(job)
      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_requeue_job') do |job|
        job.process(current_user)
      end
    end

    def stage_dependent_jobs
      # Get all jobs after the earliest stage of the inputted jobs
      min_stage_idx = @processables.map(&:stage_idx).min
      @pipeline.processables.after_stage(min_stage_idx)
    end

    def needs_dependent_jobs
      # We must include the hierarchy base here because @processables may include both a parent job
      # and its dependents, and we do not want to exclude those dependents from being processed.
      ::Gitlab::Ci::ProcessableObjectHierarchy.new(
        ::Ci::Processable.where(id: @processables.map(&:id))
      ).base_and_descendants
    end

    def ordered_by_dag(jobs)
      sorted_job_names = sort_jobs(jobs).each_with_index.to_h

      jobs.group_by(&:stage_idx).flat_map do |_, stage_jobs|
        stage_jobs.sort_by { |job| sorted_job_names.fetch(job.name) }
      end
    end

    def sort_jobs(jobs)
      Gitlab::Ci::YamlProcessor::Dag.order(
        jobs.to_h do |job|
          [job.name, job.needs.map(&:name)]
        end
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
