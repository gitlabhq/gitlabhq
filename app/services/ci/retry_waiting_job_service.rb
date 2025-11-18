# frozen_string_literal: true

module Ci
  class RetryWaitingJobService
    attr_reader :build, :metrics

    def initialize(build, metrics = ::Gitlab::Ci::Queue::Metrics)
      @build = build
      @metrics = metrics
    end

    def execute
      metrics.increment_queue_operation(:runner_queue_timeout)

      return job_not_waiting_error if build.nil? || build.runner_ack_wait_status == :not_waiting
      return job_not_finished_waiting_error if build.runner_ack_wait_status != :wait_expired

      # build.drop! will cause build to be retried automatically, if the retry count is below the limit
      build.drop!(:runner_provisioning_timeout)

      return job_not_auto_retryable_error unless build.retried?

      ServiceResponse.success
    end

    private

    def job_not_waiting_error
      ServiceResponse.error(message: 'Job is not in waiting state', payload: { reason: :not_in_waiting_state })
    end

    def job_not_finished_waiting_error
      ServiceResponse.error(message: 'Job is not finished waiting', payload: { reason: :not_finished_waiting })
    end

    def job_not_auto_retryable_error
      ServiceResponse.error(message: 'Job is not auto-retryable', payload: { job: build, reason: :not_auto_retryable })
    end
  end
end
