# frozen_string_literal: true

# Second stage of the retry chain. See RetryQueue.

module ActiveContext
  class SecondRetryQueue < RetryQueue
    PROCESSING_DELAY = 30.minutes

    class << self
      def failure_queue
        ThirdRetryQueue
      end
    end
  end
end
