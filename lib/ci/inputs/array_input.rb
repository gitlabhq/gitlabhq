# frozen_string_literal: true

module Ci
  module Inputs
    class ArrayInput < BaseInput
      extend ::Gitlab::Utils::Override

      def self.type_name
        'array'
      end

      override :validate_type
      def validate_type(value, default)
        return if value.is_a?(Array)

        error("#{default ? 'default' : 'provided'} value is not an array")
      end

      override :validate_options
      def validate_options(value, all_params = {})
        allowed_options = rules ? resolved_options(all_params) : options
        return unless allowed_options && value
        return unless value.is_a?(Array)

        invalid = value - allowed_options
        return if invalid.empty?

        error("#{invalid.join(', ')} cannot be used because it is not in the list of allowed options")
      end
    end
  end
end
