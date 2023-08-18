# frozen_string_literal: true

module Environments
  class StopJobSuccessWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :continuous_delivery

    def perform(job_id, _params = {})
      Ci::Build.find_by_id(job_id).try do |build|
        stop_environment(build) if build.stops_environment? && build.stop_action_successful?
      end
    end

    private

    def stop_environment(build)
      build.persisted_environment.fire_state_event(:stop_complete)
    end
  end
end
