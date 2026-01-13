# frozen_string_literal: true

module Ci
  module Inputs
    class ProcessorService
      def initialize(job, inputs)
        @job = job
        @inputs = inputs
      end

      def execute
        error_message = validate_inputs

        return ServiceResponse.error(message: error_message) if error_message

        filtered_inputs = filter_inputs_with_defaults

        ServiceResponse.success(payload: { inputs: filtered_inputs })
      end

      private

      attr_reader :job, :inputs

      def validate_inputs
        return if inputs.blank?

        inputs_spec = job.options[:inputs]

        return unless inputs_spec.present?

        provided_input_keys = inputs.keys.map(&:to_s)
        spec_keys = inputs_spec.keys.map(&:to_s)
        unknown_inputs = provided_input_keys - spec_keys

        if unknown_inputs.any?
          return "Unknown input#{'s' if unknown_inputs.size > 1}: #{unknown_inputs.join(', ')}"
        end

        provided_spec_keys = inputs_spec.keys.select { |key| provided_input_keys.include?(key.to_s) }
        provided_specs = inputs_spec.slice(*provided_spec_keys)
        builder = ::Ci::Inputs::Builder.new(provided_specs)

        builder.validate_input_params!(inputs)

        builder.errors.join(', ') if builder.errors.any?
      end

      def filter_inputs_with_defaults
        return {} if inputs.blank?

        inputs_spec = job.options[:inputs]

        return inputs unless inputs_spec.present?

        inputs.reject do |name, value|
          spec = inputs_spec[name]

          next false unless spec&.key?(:default)

          value == spec[:default]
        end
      end
    end
  end
end
