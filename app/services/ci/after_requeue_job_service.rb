# frozen_string_literal: true

module Ci
  class AfterRequeueJobService < ::BaseService
    def execute(processable)
      @processable = processable

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
      @processable.pipeline.reset_source_bridge!(current_user)
    end

    def dependent_jobs
      ordered_by_dag(
        stage_dependent_jobs.or(needs_dependent_jobs).ordered_by_stage
      )
    end

    def process(job)
      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_requeue_job') do |job|
        job.process(current_user)
      end
    end

    def stage_dependent_jobs
      skipped_jobs.after_stage(@processable.stage_idx)
    end

    def needs_dependent_jobs
      skipped_jobs.scheduling_type_dag.with_needs([@processable.name])
    end

    def skipped_jobs
      @skipped_jobs ||= @processable.pipeline.processables.skipped
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def ordered_by_dag(jobs)
      sorted_job_names = sort_jobs(jobs).each_with_index.to_h

      jobs.preload(:needs).group_by(&:stage_idx).flat_map do |_, stage_jobs|
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
