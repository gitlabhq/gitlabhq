# frozen_string_literal: true

module Chaos
  class KillWorker
    include ApplicationWorker
    include ChaosQueue

    def perform
      Gitlab::Chaos.kill
    end
  end
end
