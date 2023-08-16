# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class BooleanInput < BaseInput
            def self.matches?(spec)
              spec.is_a?(Hash) && spec[:type] == type_name
            end

            def self.type_name
              'boolean'
            end

            def valid_value?(value)
              [true, false].include?(value)
            end
          end
        end
      end
    end
  end
end
