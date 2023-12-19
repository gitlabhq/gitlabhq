# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          ##
          # This is a common abstraction for all input types
          class BaseInput
            ArgumentNotValidError = Class.new(StandardError)

            def self.matches?(spec)
              spec.is_a?(Hash) && spec[:type] == type_name
            end

            # Human readable type used in error messages
            def self.type_name
              raise NotImplementedError
            end

            attr_reader :errors, :name, :spec, :value

            def initialize(name:, spec:, value:)
              @name = name
              @errors = []

              # Treat minimal spec definition (nil) as a valid hash:
              #   spec:
              #     inputs:
              #       website:
              @spec = spec || {} # specification from input definition
              @value = value     # actual value provided by the user

              validate!
            end

            def to_hash
              raise ArgumentNotValidError unless valid?

              { name => actual_value }
            end

            def valid?
              @errors.none?
            end

            private

            def validate!
              validate_required

              return if errors.present?

              run_validations(default, default: true) unless required_input?

              run_validations(value) unless value.nil?
            end

            def validate_required
              error('required value has not been provided') if required_input? && value.nil?
            end

            def run_validations(value, default: false)
              validate_type(value, default)
              validate_options(value)
              validate_regex(value, default)
            end

            # Type validations are done separately for different input types.
            def validate_type(_value, _default)
              raise NotImplementedError
            end

            # Options can be either StringInput or NumberInput and are validated accordingly.
            def validate_options(_value)
              return unless options

              error('Options can only be used with string and number inputs')
            end

            # Regex can be only be a StringInput and is validated accordingly.
            def validate_regex(_value, _default)
              return unless spec.key?(:regex)

              error('RegEx validation can only be used with string inputs')
            end

            def error(message)
              @errors.push("`#{name}` input: #{message}")
            end

            def actual_value
              # nil check is to support boolean values.
              value.nil? ? default : value
            end

            # An input specification without a default value is required.
            # For example:
            # ```yaml
            # spec:
            #   inputs:
            #     website:
            # ```
            def required_input?
              !spec.key?(:default)
            end

            def default
              spec[:default]
            end

            def options
              spec[:options]
            end
          end
        end
      end
    end
  end
end
