# frozen_string_literal: true

module Ci
  module PipelineCreation
    module Inputs
      ##
      # This is a common abstraction for all input types
      class BaseInput
        include Gitlab::Utils::StrongMemoize

        def self.matches?(spec)
          spec.is_a?(Hash) && spec[:type] == type_name
        end

        # Human readable type used in error messages
        def self.type_name
          raise NotImplementedError
        end

        attr_reader :errors, :name, :spec

        def initialize(name:, spec:)
          @name = name
          @errors = []

          # Treat minimal spec definition (nil) as a valid hash:
          #   spec:
          #     inputs:
          #       website:
          @spec = spec || {} # specification from input definition
        end

        def validate_param!(param)
          error('required value has not been provided') if required? && param.nil?
          return if errors.present?

          run_validations(default, default: true) unless required?
          run_validations(param) unless param.nil?
        end

        def actual_value(param)
          # nil check is to support boolean values.
          param.nil? ? coerced_value(default) : coerced_value(param)
        end

        def type
          self.class.type_name
        end

        # An input specification without a default value is required.
        # For example:
        # ```yaml
        # spec:
        #   inputs:
        #     website:
        # ```
        def required?
          !spec.key?(:default)
        end

        def default
          spec[:default]
        end

        def options
          spec[:options]
        end

        def description
          spec[:description]
        end

        def regex
          return unless regex_provided?

          spec[:regex]
        end

        private

        def run_validations(value, default: false)
          value = coerced_value(value)

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
          return unless regex_provided?

          error('RegEx validation can only be used with string inputs')
        end

        def regex_provided?
          spec.key?(:regex)
        end

        def error(message)
          @errors.push("`#{name}` input: #{message}")
        end

        def coerced_value(value)
          strong_memoize_with(:coerced_value, value) do
            next if value.nil?

            Gitlab::Json.parse(value)
          rescue JSON::ParserError
            value
          end
        end
      end
    end
  end
end
