# frozen_string_literal: true

module Ci
  module PipelineCreation
    class PushOptions
      def self.fabricate(push_options)
        if push_options.is_a?(self)
          push_options
        elsif push_options.is_a?(Hash)
          new(push_options)
        elsif push_options.blank?
          new({})
        else
          raise ArgumentError, 'Unknown type of push_option'
        end
      end

      def initialize(push_options)
        @push_options = push_options&.deep_symbolize_keys || {}
      end

      def skips_ci?
        push_options.dig(:ci, :skip).present?
      end

      def variables
        raw_push_options_variables = push_options.dig(:ci, :variable)
        return [] unless raw_push_options_variables

        raw_vars = extract_key_value_pairs_from_push_option(raw_push_options_variables)

        raw_vars.map do |key, value|
          { "key" => key, "variable_type" => "env_var", "secret_value" => value }
        end
      end

      def inputs
        raw_push_options_inputs = push_options.dig(:ci, :input)
        return {} unless raw_push_options_inputs

        raw_inputs = extract_key_value_pairs_from_push_option(raw_push_options_inputs)
        ::Ci::PipelineCreation::Inputs.parse_params(raw_inputs.to_h)
      end

      private

      attr_reader :push_options

      def extract_key_value_pairs_from_push_option(push_option)
        # When extracting variables and encountering a missing `key` or `value`, this is valid:
        #  "ABC=" -> `key` would be `ABC` and value an empty string
        # These formats are invalid and will be ignored:
        #  "=123" -> `key` would be an empty string
        #  "ABC"  -> `value` would be nil

        return [] unless push_option

        push_option.each_with_object([]) do |(raw_value, _), result|
          key, value = raw_value.to_s.split("=", 2)
          next if key.blank? || value.nil?

          result << [key, value]
        end
      end
    end
  end
end
