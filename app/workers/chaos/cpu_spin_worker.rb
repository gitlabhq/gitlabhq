# frozen_string_literal: true

module Chaos
  class CpuSpinWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include ChaosQueue

    def perform(duration_s)
      Gitlab::Chaos.cpu_spin(duration_s)
    end
  end
end
