# frozen_string_literal: true

module Environments
  class StopJobFailedWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :continuous_delivery

    def perform(job_id, _params = {})
      Ci::Processable.find_by_id(job_id).try do |job|
        revert_environment(job) if job.stops_environment? && job.failed?
      end
    end

    private

    def revert_environment(job)
      return if job.persisted_environment.nil?

      job.persisted_environment.fire_state_event(:recover_stuck_stopping)
    end
  end
end
