# frozen_string_literal: true

module Gitlab
  module Utils
    class TimeIntegerConverter
      INVALID_INPUT_TYPE = Class.new(StandardError)
      MICROSECONDS = 1_000_000
      ALLOWED_TIME_CLASSES = [Time, ActiveSupport::TimeWithZone].freeze
      ALLOWED_INTEGER_CLASSES = [Integer, String].freeze

      def initialize(input, precision = MICROSECONDS)
        @input = input
        @precision = precision
      end

      def to_time
        raise INVALID_INPUT_TYPE, 'input must be an Integer' unless ALLOWED_INTEGER_CLASSES.any? { |k| @input.is_a?(k) }

        integer = Integer(@input)

        Time.at(Rational(integer, @precision)).in_time_zone
      rescue ArgumentError
        raise INVALID_INPUT_TYPE, 'input must be an Integer'
      end

      def to_i
        return unless @input

        unless ALLOWED_TIME_CLASSES.any? { |k| @input.is_a?(k) }
          raise INVALID_INPUT_TYPE, 'input must be a valid Time object'
        end

        (@input.to_r * @precision).to_i
      end
    end
  end
end
