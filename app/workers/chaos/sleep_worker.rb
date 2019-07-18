# frozen_string_literal: true

module Chaos
  class SleepWorker
    include ApplicationWorker
    include ChaosQueue

    def perform(duration_s)
      Gitlab::Chaos.sleep(duration_s)
    end
  end
end
