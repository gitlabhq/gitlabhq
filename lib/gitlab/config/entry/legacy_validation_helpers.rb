# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module LegacyValidationHelpers
        private

        def validate_array_of_strings(values)
          values.is_a?(Array) && values.all? { |value| validate_string(value) }
        end

        def validate_string(value)
          value.is_a?(String) || value.is_a?(Symbol)
        end
      end
    end
  end
end
