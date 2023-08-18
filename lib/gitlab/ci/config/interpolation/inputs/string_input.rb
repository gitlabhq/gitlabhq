# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class StringInput < BaseInput
            def self.matches?(spec)
              # The input spec can be `nil` when using a minimal specification
              # and also when `type` is not specified.
              #
              # ```yaml
              # spec:
              #   inputs:
              #     foo:
              # ```
              spec.nil? || (spec.is_a?(Hash) && [nil, type_name].include?(spec[:type]))
            end

            def self.type_name
              'string'
            end

            def valid_value?(value)
              value.nil? || value.is_a?(String)
            end
          end
        end
      end
    end
  end
end
