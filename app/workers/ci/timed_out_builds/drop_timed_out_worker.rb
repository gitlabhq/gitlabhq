# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropTimedOutWorker
      include ApplicationWorker
      # rubocop:disable Scalability/CronWorkerContext -- This is an instance-wide cleanup query
      include CronjobQueue

      # rubocop:enable Scalability/CronWorkerContext

      idempotent!
      data_consistency :sticky
      feature_category :continuous_integration
      deduplicate :until_executed, ttl: 30.minutes
      queue_namespace :cronjob

      def perform
        DropTimedOutService.new.execute
      end
    end
  end
end
