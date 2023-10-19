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

            private

            def validate_regex!
              return unless spec.key?(:regex)

              safe_regex = ::Gitlab::UntrustedRegexp.new(spec[:regex])

              return if safe_regex.match?(actual_value)

              if value.nil?
                error('default value does not match required RegEx pattern')
              else
                error('provided value does not match required RegEx pattern')
              end
            rescue RegexpError
              error('invalid regular expression')
            end
          end
        end
      end
    end
  end
end
