# frozen_string_literal: true

module Ci
  module PipelineCreation
    module Inputs
      class SpecInputs
        TYPES = [
          ArrayInput,
          BooleanInput,
          NumberInput,
          StringInput
        ].freeze

        def self.input_types
          TYPES.map(&:type_name)
        end

        # @param specs [Hash] A hash containing inputs specifications from `spec:inputs` config header
        def initialize(specs)
          @inputs = []
          @errors = []

          build_inputs!(specs.to_h)
        end

        def all_inputs
          @inputs
        end

        def input_names
          all_inputs.map(&:name)
        end

        def errors
          @errors + all_inputs.flat_map(&:errors)
        end

        def validate_input_params!(params)
          all_inputs.each do |input|
            input.validate_param!(params[input.name])
          end
        end

        def to_params(params)
          all_inputs.inject({}) do |hash, input|
            hash.merge(input.name => input.actual_value(params[input.name]))
          end
        end

        private

        def build_inputs!(specs)
          specs.each do |input_name, spec|
            input_type = TYPES.find { |klass| klass.matches?(spec) }

            unless input_type
              @errors.push(
                "unknown input specification for `#{input_name}` (valid types: #{self.class.input_types.join(', ')})")
              next
            end

            @inputs << input_type.new(name: input_name, spec: spec)
          end
        end
      end
    end
  end
end
