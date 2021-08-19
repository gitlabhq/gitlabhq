# frozen_string_literal: true

module Environments
  class AutoStopCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :continuous_delivery
    worker_resource_boundary :cpu

    def perform
      AutoStopService.new.execute
    end
  end
end
