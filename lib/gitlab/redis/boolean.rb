# frozen_string_literal: true

# A serializer for boolean values being stored in Redis.
#
# This is to ensure that booleans are stored in a consistent and
# testable way when being stored as strings in Redis.
#
# Examples:
#
#     bool = Gitlab::Redis::Boolean.new(true)
#     bool.to_s == "_b:1"
#
#     Gitlab::Redis::Boolean.encode(true)
#     => "_b:1"
#
#     Gitlab::Redis::Boolean.decode("_b:1")
#     => true
#
#     Gitlab::Redis::Boolean.true?("_b:1")
#     => true
#
#     Gitlab::Redis::Boolean.true?("_b:0")
#     => false

module Gitlab
  module Redis
    class Boolean
      LABEL = "_b"
      DELIMITER = ":"
      TRUE_STR = "1"
      FALSE_STR = "0"

      BooleanError = Class.new(StandardError)
      NotABooleanError = Class.new(BooleanError)
      NotAnEncodedBooleanStringError = Class.new(BooleanError)

      def initialize(value)
        @value = value
      end

      # @return [String] the encoded boolean
      def to_s
        self.class.encode(@value)
      end

      class << self
        # Turn a boolean into a string for storage in Redis
        #
        # @param value [Boolean] true or false
        # @return [String] the encoded boolean
        # @raise [NotABooleanError] if the value isn't true or false
        def encode(value)
          raise NotABooleanError, value unless bool?(value)

          [LABEL, to_string(value)].join(DELIMITER)
        end

        # Decode a boolean string
        #
        # @param value [String] the stored boolean string
        # @return [Boolean] true or false
        # @raise [NotAnEncodedBooleanStringError] if the provided value isn't an encoded boolean
        def decode(value)
          raise NotAnEncodedBooleanStringError, value.class unless value.is_a?(String)

          label, bool_str = *value.split(DELIMITER, 2)

          raise NotAnEncodedBooleanStringError, label unless label == LABEL

          from_string(bool_str)
        end

        # Decode a boolean string, then test if it's true
        #
        # @param value [String] the stored boolean string
        # @return [Boolean] is the value true?
        # @raise [NotAnEncodedBooleanStringError] if the provided value isn't an encoded boolean
        def true?(encoded_value)
          decode(encoded_value)
        end

        # Decode a boolean string, then test if it's false
        #
        # @param value [String] the stored boolean string
        # @return [Boolean] is the value false?
        # @raise [NotAnEncodedBooleanStringError] if the provided value isn't an encoded boolean
        def false?(encoded_value)
          !true?(encoded_value)
        end

        private

        def bool?(value)
          [true, false].include?(value)
        end

        def to_string(bool)
          bool ? TRUE_STR : FALSE_STR
        end

        def from_string(str)
          raise NotAnEncodedBooleanStringError, str unless [TRUE_STR, FALSE_STR].include?(str)

          str == TRUE_STR
        end
      end
    end
  end
end
