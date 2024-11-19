# frozen_string_literal: true

module Chaos
  class SleepWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 3
    include ChaosQueue

    def perform(duration_s)
      Gitlab::Chaos.sleep(duration_s)
    end
  end
end
