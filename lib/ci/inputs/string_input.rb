# frozen_string_literal: true

module Ci
  module Inputs
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
      def validate_type(value, _default)
        # Since coerced_value always converts to string via value.to_s,
        # this validation will always pass for StringInput
      end

      override :validate_options
      def validate_options(value)
        return unless options && value
        return if options.map(&:to_s).include?(value)

        error("`#{value}` cannot be used because it is not in the list of allowed options")
      end

      private

      override :validate_regex
      def validate_regex(value, default)
        return unless regex_provided? && value.is_a?(String)

        safe_regex = ::Gitlab::UntrustedRegexp.new(regex)

        return if safe_regex.match?(value, allow_empty_string: true)

        error("#{default ? 'default' : 'provided'} value does not match required RegEx pattern")
      rescue RegexpError
        error('invalid regular expression')
      end

      override :coerced_value
      def coerced_value(value)
        value.to_s
      end
    end
  end
end
