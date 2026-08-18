# frozen_string_literal: true

module Gitlab
  module Utils
    # This class estimates the JSON blob byte size of a ruby object using as
    # little allocations as possible.
    # The estimation should be quite accurate when using simple objects.
    #
    # Example:
    #
    # Gitlab::Utils::JsonSizeEstimator.estimate(["a", { b: 12, c: nil }])
    # Gitlab::Utils::JsonSizeEstimator.estimate(data, max_size: 1024) # aborts early if estimate > 1024
    class JsonSizeEstimator
      ARRAY_BRACKETS_SIZE = 2 # []
      OBJECT_BRACKETS_SIZE = 2 # {}
      DOUBLEQUOTE_SIZE = 2 # ""
      COLON_SIZE = 1 # : character size from {"a": 1}
      MINUS_SIGN_SIZE = 1 # - character size from -1
      NULL_SIZE = 4 # null

      SizeExceededError = Class.new(StandardError)

      class << self
        # Returns: integer (number of bytes)
        # Raises SizeExceededError if max_size is provided and estimate exceeds it
        def estimate(object, max_size: nil)
          new(max_size: max_size).estimate(object)
        end
      end

      def initialize(max_size: nil)
        @max_size = max_size
        @current_size = 0
      end

      def estimate(object)
        case object
        when Hash
          estimate_hash(object)
        when Array
          estimate_array(object)
        when String
          account(estimate_string(object))
        when Integer
          account(estimate_integer(object))
        when Float
          account(estimate_float(object))
        when DateTime, Time
          account(estimate_time(object))
        when NilClass
          account(NULL_SIZE)
        else
          # might be incorrect, but #to_s is safe, #to_json might be disabled for some objects: User
          account(estimate_string(object.to_s))
        end
      end

      private

      # Accumulates the running size and aborts early once it exceeds
      # +@max_size+. Each node accounts only for its own direct contribution
      # (brackets, commas, colons, or a scalar); children account for
      # themselves via recursion, so the running total is never double-counted.
      def account(size)
        return size unless @max_size

        @current_size += size

        if @current_size > @max_size
          raise SizeExceededError,
            "Estimated JSON size (#{@current_size}) exceeds limit (#{@max_size})"
        end

        size
      end

      def estimate_hash(hash)
        item_count = hash.size
        size = account(OBJECT_BRACKETS_SIZE + comma_count(item_count) + (item_count * COLON_SIZE))

        hash.each do |key, value|
          size += estimate(key.to_s)
          size += estimate(value)
        end

        size
      end

      def estimate_array(array)
        size = account(ARRAY_BRACKETS_SIZE + comma_count(array.size))

        array.each { |item| size += estimate(item) }

        size
      end

      def estimate_string(string)
        string.bytesize + DOUBLEQUOTE_SIZE
      end

      def estimate_float(float)
        float.to_s.bytesize
      end

      def estimate_integer(integer)
        if integer > 0
          integer_string_size(integer)
        elsif integer < 0
          integer_string_size(integer.abs) + MINUS_SIGN_SIZE
        else # 0
          1
        end
      end

      def estimate_time(time)
        time.to_json.size
      end

      def integer_string_size(integer)
        Math.log10(integer).floor + 1
      end

      def comma_count(item_count)
        item_count == 0 ? 0 : item_count - 1
      end
    end
  end
end
