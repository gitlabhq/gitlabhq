module Gitlab
  module Ci
    class Config
      module Entry
        module LegacyValidationHelpers
          private

          def validate_duration(value)
            value.is_a?(String) && ChronicDuration.parse(value)
          rescue ChronicDuration::DurationParseError
            false
          end

          def validate_array_of_strings(values)
            values.is_a?(Array) && values.all? { |value| validate_string(value) }
          end

          def validate_array_of_strings_or_regexps(values)
            values.is_a?(Array) && values.all? { |value| validate_string_or_regexp(value) }
          end

          def validate_variables(variables)
            variables.is_a?(Hash) &&
              variables.all? { |key, value| validate_string(key) && validate_string(value) }
          end

          def validate_string(value)
            value.is_a?(String) || value.is_a?(Symbol)
          end

          def validate_string_or_regexp(value)
            return true if value.is_a?(Symbol)
            return false unless value.is_a?(String)

            if value.first == '/' && value.last == '/'
              Regexp.new(value[1...-1])
            else
              true
            end
          rescue RegexpError
            false
          end

          def validate_boolean(value)
            value.in?([true, false])
          end
        end
      end
    end
  end
end
