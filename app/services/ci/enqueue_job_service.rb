# frozen_string_literal: true

module Ci
  class EnqueueJobService
    attr_accessor :job, :current_user, :variables

    def initialize(job, current_user:, variables: nil)
      @job = job
      @current_user = current_user
      @variables = variables
    end

    def execute(&transition)
      transition ||= ->(job) { job.enqueue! }

      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_enqueue_job') do |job|
        job.user = current_user
        job.job_variables_attributes = variables if variables

        transition.call(job)
      end

      ResetSkippedJobsService.new(job.project, current_user).execute(job)

      job
    end
  end
end
