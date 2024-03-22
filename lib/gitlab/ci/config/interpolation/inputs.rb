# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        # Interpolation inputs provided by the user.
        class Inputs
          UnknownInputTypeError = Class.new(StandardError)

          TYPES = [
            ArrayInput,
            BooleanInput,
            NumberInput,
            StringInput
          ].freeze

          def self.input_types
            TYPES.map(&:type_name)
          end

          def initialize(specs, args)
            @specs = specs.to_h
            @args = args.to_h
            @inputs = []
            @errors = []

            validate!
            fabricate!
          end

          def errors
            @errors + @inputs.flat_map(&:errors)
          end

          def valid?
            errors.none?
          end

          def to_hash
            @inputs.inject({}) do |hash, input|
              hash.merge(input.to_hash)
            end
          end

          private

          def validate!
            unknown_inputs = @args.keys - @specs.keys
            return if unknown_inputs.empty?

            @errors.push("unknown input arguments: #{unknown_inputs.join(', ')}")
          end

          def fabricate!
            @specs.each do |input_name, spec|
              input_type = TYPES.find { |klass| klass.matches?(spec) }

              unless input_type
                @errors.push(
                  "unknown input specification for `#{input_name}` (valid types: #{valid_type_names.join(', ')})")
                next
              end

              @inputs.push(input_type.new(
                name: input_name,
                spec: spec,
                value: @args[input_name]))
            end
          end

          def valid_type_names
            TYPES.map(&:type_name)
          end
        end
      end
    end
  end
end
