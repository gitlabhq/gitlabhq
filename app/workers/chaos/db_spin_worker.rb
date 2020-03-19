# frozen_string_literal: true

module Chaos
  class DbSpinWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include ChaosQueue

    def perform(duration_s, interval_s)
      Gitlab::Chaos.db_spin(duration_s, interval_s)
    end
  end
end
