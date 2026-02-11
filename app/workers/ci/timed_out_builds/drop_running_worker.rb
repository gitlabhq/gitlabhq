# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropRunningWorker
      include ApplicationWorker

      idempotent!
      data_consistency :sticky
      feature_category :continuous_integration
      deduplicate :until_executed, ttl: 30.minutes
      queue_namespace :timed_out_builds
      sidekiq_options retry: 1, dead: false

      def perform
        DropRunningService.new.execute
      end
    end
  end
end
