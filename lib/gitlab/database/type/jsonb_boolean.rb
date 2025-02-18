# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      class JsonbBoolean < ActiveModel::Type::Value
        FALSE_VALUES = [false, 0, "0", "f", "false", "off"].to_set.freeze
        TRUE_VALUES = [true, 1, "1", "t", "true", "on"].to_set.freeze

        def cast(value)
          normalized_value = normalize_value(value)
          return false if FALSE_VALUES.include?(normalized_value)

          return true if TRUE_VALUES.include?(normalized_value)

          value
        end

        private

        def normalize_value(value)
          case value
          when Symbol
            value.to_s.downcase
          when String
            value.downcase
          else
            value
          end
        end
      end
    end
  end
end
