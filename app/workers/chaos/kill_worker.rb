# frozen_string_literal: true

module Chaos
  class KillWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include ChaosQueue

    sidekiq_options retry: false

    def perform(signal)
      Gitlab::Chaos.kill(signal)
    end
  end
end
