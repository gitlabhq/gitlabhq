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

            # Checks whether the class matches the type in the specification
            def self.matches?(spec)
              raise NotImplementedError
            end

            # Human readable type used in error messages
            def self.type_name
              raise NotImplementedError
            end

            # Checks whether the provided value is of the given type
            def valid_value?(value)
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
              return error('required value has not been provided') if required_input? && value.nil?

              # validate default value
              if !required_input? && !valid_value?(default)
                return error("default value is not a #{self.class.type_name}")
              end

              # validate provided value
              error("provided value is not a #{self.class.type_name}") unless valid_value?(actual_value)
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
          end
        end
      end
    end
  end
end
