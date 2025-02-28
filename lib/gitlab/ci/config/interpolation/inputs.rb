# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Inputs
          def initialize(specs, params)
            @spec_inputs = ::Ci::PipelineCreation::Inputs::SpecInputs.new(specs)
            @params = params.to_h
            @params_errors = []

            validate_params!
          end

          def errors
            @params_errors + @spec_inputs.errors
          end

          def valid?
            errors.none?
          end

          def to_hash
            @spec_inputs.to_params(@params)
          end

          private

          def validate_params!
            @spec_inputs.validate_input_params!(@params)
            return if @params_errors.any?

            check_if_unknown_inputs_provided!
          end

          def check_if_unknown_inputs_provided!
            unknown_inputs = @params.keys - @spec_inputs.input_names
            return if unknown_inputs.empty?

            @params_errors.push("unknown input arguments: #{unknown_inputs.join(', ')}")
          end
        end
      end
    end
  end
end
