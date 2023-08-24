# frozen_string_literal: true

module Environments
  class StopJobSuccessWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :continuous_delivery

    def perform(job_id, _params = {})
      Ci::Processable.find_by_id(job_id).try do |job|
        stop_environment(job) if job.stops_environment? && job.stop_action_successful?
      end
    end

    private

    def stop_environment(job)
      job.persisted_environment.fire_state_event(:stop_complete)
    end
  end
end
