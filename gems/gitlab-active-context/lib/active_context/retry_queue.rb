# frozen_string_literal: true

# RetryQueue handles failed processing attempts by storing them for retry.
# Items in this queue are processed once. If they fail again, they are moved to the DeadQueue.
# Items only become visible for processing PROCESSING_DELAY after they are pushed, giving
# transient errors (for example, AI Gateway timeouts) time to clear before the single retry.

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
        PROCESSING_DELAY
      end
    end
  end
end
