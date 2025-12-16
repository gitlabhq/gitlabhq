# frozen_string_literal: true

# DeadQueue stores items that have failed processing in the RetryQueue.
# Items in this queue are not automatically processed and require manual intervention.

module ActiveContext
  class DeadQueue
    include Concerns::Queue

    class << self
      def number_of_shards
        1
      end
    end
  end
end
