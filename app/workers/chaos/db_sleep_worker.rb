# frozen_string_literal: true

module Chaos #  rubocop:disable Gitlab/BoundedContexts -- used to introduce chaos in various GitLab components
  class DbSleepWorker # rubocop:disable Scalability/IdempotentWorker -- a test worker
    include ApplicationWorker

    data_consistency :sticky

    concurrency_limit -> { 2500 } # to test against sidekiq throttling middleware
    sidekiq_options retry: false

    include ChaosQueue

    def perform(duration_s)
      Gitlab::Chaos.db_sleep(duration_s)
    end
  end
end
