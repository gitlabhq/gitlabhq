# frozen_string_literal: true

module Chaos
  class KillWorker
    include ApplicationWorker
    include ChaosQueue

    sidekiq_options retry: false

    def perform
      Gitlab::Chaos.kill
    end
  end
end
