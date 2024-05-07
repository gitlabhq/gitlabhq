# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Metadata
        # Defines value parsing and formatting routines for backup metadata JSON
        module Serializer
          extend self

          # Given a metadata value, prepare and format the value as a
          # JSON primitive type before serializing
          #
          # @param [Symbol] type
          # @param [String|Time|Integer] value
          # @return [Integer, String] the converted JSON primitive value
          def serialize_value(type:, value:)
            return value if value.nil?

            case type
            when :string then serialize_string(value)
            when :time then serialize_time(value)
            when :integer then serialize_integer(value)
            else
              raise ArgumentError, "Unknown data type key #{type.inspect} provided when serializing backup metadata"
            end
          end

          # Serialize the integer value
          #
          # @return [Integer]
          def serialize_integer(value)
            return value if value.nil?

            value.to_i
          end

          # Serialize the String value
          #
          # @return [String]
          def serialize_string(value)
            value.to_s
          end

          # Serialize the Time value using ISO8601 format
          #
          # @return [String]
          def serialize_time(value)
            return value if value.nil?
            raise ArgumentError unless value.is_a?(Time)

            # ensures string values and nil are properly cast to Time objects
            value.iso8601
          end
        end
      end
    end
  end
end
