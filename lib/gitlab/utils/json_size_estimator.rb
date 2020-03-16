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
    class JsonSizeEstimator
      ARRAY_BRACKETS_SIZE = 2 # []
      OBJECT_BRACKETS_SIZE = 2 # {}
      DOUBLEQUOTE_SIZE = 2 # ""
      COLON_SIZE = 1 # : character size from {"a": 1}
      MINUS_SIGN_SIZE = 1 # - character size from -1
      NULL_SIZE = 4 # null

      class << self
        # Returns: integer (number of bytes)
        def estimate(object)
          case object
          when Hash
            estimate_hash(object)
          when Array
            estimate_array(object)
          when String
            estimate_string(object)
          when Integer
            estimate_integer(object)
          when Float
            estimate_float(object)
          when DateTime, Time
            estimate_time(object)
          when NilClass
            NULL_SIZE
          else
            # might be incorrect, but #to_s is safe, #to_json might be disabled for some objects: User
            estimate_string(object.to_s)
          end
        end

        private

        def estimate_hash(hash)
          size = 0
          item_count = 0

          hash.each do |key, value|
            item_count += 1

            size += estimate(key.to_s) + COLON_SIZE + estimate(value)
          end

          size + OBJECT_BRACKETS_SIZE + comma_count(item_count)
        end

        def estimate_array(array)
          size = 0
          item_count = 0

          array.each do |item|
            item_count += 1

            size += estimate(item)
          end

          size + ARRAY_BRACKETS_SIZE + comma_count(item_count)
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
end
