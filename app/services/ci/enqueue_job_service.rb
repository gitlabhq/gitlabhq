# frozen_string_literal: true

module Ci
  class EnqueueJobService
    attr_accessor :job, :current_user, :variables, :inputs

    def initialize(job, current_user:, variables: nil, inputs: {})
      @job = job
      @current_user = current_user
      @variables = variables
      @inputs = inputs
    end

    def execute
      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_enqueue_job') do |job|
        job.user = current_user
        job.job_variables_attributes = variables if variables

        if inputs.present?
          job.inputs_attributes = inputs.map do |name, value|
            { name: name, value: value, project: job.project }
          end
        end

        job.enqueue!
      end

      ResetSkippedJobsService.new(job.project, current_user).execute(job)

      job
    end
  end
end
