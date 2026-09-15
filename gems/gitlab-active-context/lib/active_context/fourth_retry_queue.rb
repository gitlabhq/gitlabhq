# frozen_string_literal: true

# Fourth and last stage of the retry chain. See RetryQueue.

module ActiveContext
  class FourthRetryQueue < RetryQueue
    PROCESSING_DELAY = 8.hours

    class << self
      def failure_queue
        DeadQueue
      end
    end
  end
end
