# frozen_string_literal: true

module Environments
  class AutoStopWorker
    include ApplicationWorker

    data_consistency :always
    idempotent!
    feature_category :continuous_delivery

    def perform(environment_id, params = {})
      Environment.find_by_id(environment_id).try do |environment|
        user = environment.stop_action&.user
        environment.stop_with_action!(user)
      end
    end
  end
end
