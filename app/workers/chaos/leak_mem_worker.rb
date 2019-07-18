# frozen_string_literal: true

module Chaos
  class LeakMemWorker
    include ApplicationWorker
    include ChaosQueue

    def perform(memory_mb, duration_s)
      Gitlab::Chaos.leak_mem(memory_mb, duration_s)
    end
  end
end
