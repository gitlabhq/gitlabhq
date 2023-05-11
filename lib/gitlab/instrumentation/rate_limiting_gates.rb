# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class RateLimitingGates
      GATES = :rate_limiting_gates

      InstrumentationStorage = ::Gitlab::Instrumentation::Storage

      class << self
        def track(key)
          if InstrumentationStorage.active?
            gates_set << key
          end
        end

        def gates
          gates_set.to_a
        end

        def payload
          {
            GATES => gates
          }
        end

        private

        def gates_set
          InstrumentationStorage[GATES] ||= Set.new
        end
      end
    end
  end
end
