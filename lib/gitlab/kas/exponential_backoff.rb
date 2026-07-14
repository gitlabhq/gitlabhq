# frozen_string_literal: true

module Gitlab
  module Kas
    # Stateful exponential backoff for {Gitlab::Kas::Client#subscribe_events} reconnects.
    #
    # Uses "full jitter" (AWS Architecture Blog): the returned delay is random in `[0, delay]`, which
    # spreads out reconnects best to avoid storms against a shared KAS. Not thread-safe; one instance
    # per subscribing thread.
    class ExponentialBackoff
      def initialize(min: 1, max: 30, multiplier: 2, jitter: true)
        @min = min
        @max = max
        @multiplier = multiplier
        @jitter = jitter

        reset
      end

      # Jitter is applied to the returned value only; the deterministic `@current` is what advances,
      # so growth toward `max` is unaffected by jitter.
      def next
        delay = @current
        @current = [@current * @multiplier, @max].min

        @jitter ? rand * delay : delay
      end

      def reset
        @current = @min

        nil
      end
    end
  end
end
