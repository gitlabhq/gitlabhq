# frozen_string_literal: true

module Environments
  class AutoStopCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :continuous_delivery

    def perform
      AutoStopService.new.execute
    end
  end
end
