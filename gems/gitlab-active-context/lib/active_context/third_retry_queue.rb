# frozen_string_literal: true

# Third stage of the retry chain. See RetryQueue.

module ActiveContext
  class ThirdRetryQueue < RetryQueue
    PROCESSING_DELAY = 2.hours

    class << self
      def failure_queue
        FourthRetryQueue
      end
    end
  end
end
