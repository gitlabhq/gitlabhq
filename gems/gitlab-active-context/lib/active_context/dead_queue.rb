# frozen_string_literal: true

# DeadQueue stores items that failed every stage of the retry chain.
# Items in this queue are never processed and need manual intervention.

module ActiveContext
  class DeadQueue
    include Concerns::Queue

    class << self
      def number_of_shards
        1
      end

      # The DeadQueue is never processed, so nothing can fail out of it.
      def failure_queue
        nil
      end
    end
  end
end
