# frozen_string_literal: true

module Environments
  class AutoStopCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :continuous_delivery

    def perform
      return unless Feature.enabled?(:auto_stop_environments, default_enabled: true)

      AutoStopService.new.execute
    end
  end
end
