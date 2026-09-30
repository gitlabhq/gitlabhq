# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module LegacyValidationHelpers
        private

        def validate_duration(value, parser = nil)
          return false unless value.is_a?(String)

          if parser && parser.respond_to?(:validate_duration)
            parser.validate_duration(value)
          else
            ChronicDuration.parse(value)
          end
        rescue ChronicDuration::DurationParseError
          false
        end

        def validate_duration_limit(value, limit, parser = nil)
          return false unless value.is_a?(String)

          if parser && parser.respond_to?(:validate_duration_limit)
            parser.validate_duration_limit(value, limit)
          else
            parsed_value = ChronicDuration.parse(value)
            parsed_limit = ChronicDuration.parse(limit)

            return false if parsed_value.nil? || parsed_limit.nil?

            parsed_value.second.from_now < parsed_limit.second.from_now
          end
        rescue ChronicDuration::DurationParseError
          false
        end

        def validate_array_of_strings(values)
          values.is_a?(Array) && values.all? { |value| validate_string(value) }
        end

        def validate_variables(variables)
          variables.is_a?(Hash) && variables.flatten.all? { |value| Validators::AlphanumericValidator.validate(value) }
        end

        def validate_array_value_variables(variables)
          variables.is_a?(Hash) &&
            variables.keys.all? { |value| Validators::AlphanumericValidator.validate(value) } &&
            variables.values.all? { |v| !v.nil? } &&
            variables.values.flatten(1).all? { |value| Validators::AlphanumericValidator.validate(value) }
        end

        def validate_integer(value)
          value.is_a?(Integer)
        end

        def validate_string(value)
          value.is_a?(String) || value.is_a?(Symbol)
        end

        def validate_boolean(value)
          value.in?([true, false])
        end
      end
    end
  end
end
