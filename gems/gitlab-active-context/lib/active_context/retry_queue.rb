# frozen_string_literal: true

# RetryQueue handles failed processing attempts by storing them for retry.
# Items in this queue are processed once. If they fail again, they are moved to the DeadQueue.

module ActiveContext
  class RetryQueue
    include Concerns::Queue

    class << self
      def number_of_shards
        1
      end
    end
  end
end
