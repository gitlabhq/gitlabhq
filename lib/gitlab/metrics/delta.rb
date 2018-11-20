# frozen_string_literal: true

module Gitlab
  module Metrics
    # Class for calculating the difference between two numeric values.
    #
    # Every call to `compared_with` updates the internal value. This makes it
    # possible to use a single Delta instance to calculate the delta over time
    # of an ever increasing number.
    #
    # Example usage:
    #
    #     delta = Delta.new(0)
    #
    #     delta.compared_with(10) # => 10
    #     delta.compared_with(15) # => 5
    #     delta.compared_with(20) # => 5
    class Delta
      def initialize(value = 0)
        @value = value
      end

      # new_value - The value to compare with as a Numeric.
      #
      # Returns a new Numeric (depending on the type of `new_value`).
      def compared_with(new_value)
        delta  = new_value - @value
        @value = new_value

        delta
      end
    end
  end
end
