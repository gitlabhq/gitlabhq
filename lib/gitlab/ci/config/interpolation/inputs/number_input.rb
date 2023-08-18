# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class NumberInput < BaseInput
            def self.matches?(spec)
              spec.is_a?(Hash) && spec[:type] == type_name
            end

            def self.type_name
              'number'
            end

            def valid_value?(value)
              value.is_a?(Numeric)
            end
          end
        end
      end
    end
  end
end
