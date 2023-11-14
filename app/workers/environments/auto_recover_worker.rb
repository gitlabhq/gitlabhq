# frozen_string_literal: true

module Environments
  class AutoRecoverWorker
    include ApplicationWorker

    deduplicate :until_executed
    data_consistency :delayed
    idempotent!
    feature_category :continuous_delivery

    def perform(environment_id, _params = {})
      Environment.find_by_id(environment_id).try do |environment|
        next unless environment.long_stopping?

        next unless environment.stop_actions.all?(&:complete?)

        environment.recover_stuck_stopping
      end
    end
  end
end
