# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          class StringInput < BaseInput
            extend ::Gitlab::Utils::Override

            def self.matches?(spec)
              # The input spec can be `nil` when using a minimal specification
              # and also when `type` is not specified.
              #
              # ```yaml
              # spec:
              #   inputs:
              #     foo:
              # ```
              spec.nil? || super || (spec.is_a?(Hash) && !spec.key?(:type))
            end

            def self.type_name
              'string'
            end

            override :validate_type
            def validate_type(value, default)
              return if value.is_a?(String)

              error("#{default ? 'default' : 'provided'} value is not a string")
            end

            override :validate_options
            def validate_options(value)
              return unless options && value
              return if options.include?(value)

              error("`#{value}` cannot be used because it is not in the list of allowed options")
            end

            private

            override :validate_regex
            def validate_regex(value, default)
              return unless spec.key?(:regex) && value.is_a?(String)

              safe_regex = ::Gitlab::UntrustedRegexp.new(spec[:regex])

              return if safe_regex.match?(value)

              error("#{default ? 'default' : 'provided'} value does not match required RegEx pattern")
            rescue RegexpError
              error('invalid regular expression')
            end
          end
        end
      end
    end
  end
end
