# frozen_string_literal: true

# RetryQueue is the first stage of the retry chain. Failed items move
# through retry queues with increasing delays before they reach the
# DeadQueue:
#
#   RetryQueue (5 min) -> SecondRetryQueue (30 min) ->
#   ThirdRetryQueue (2 h) -> FourthRetryQueue (8 h) -> DeadQueue
#
# Each stage gives one retry. Items only become visible for processing
# PROCESSING_DELAY after they are pushed, giving transient errors (for
# example, AI Gateway timeouts) time to clear between attempts.

module ActiveContext
  class RetryQueue
    include Concerns::Queue

    PROCESSING_DELAY = 5.minutes

    class << self
      def number_of_shards
        1
      end

      def extra_preprocess_options
        { skip_missing_content: true }
      end

      def processing_delay
        self::PROCESSING_DELAY
      end

      def failure_queue
        SecondRetryQueue
      end
    end
  end
end
