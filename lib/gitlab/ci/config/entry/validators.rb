module Gitlab
  module Ci
    class Config
      module Entry
        module Validators
          class AllowedKeysValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              unknown_keys = record.config.try(:keys).to_a - options[:in]

              if unknown_keys.any?
                record.errors.add(:config, 'contains unknown keys: ' +
                                            unknown_keys.join(', '))
              end
            end
          end

          class AllowedValuesValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              unless options[:in].include?(value.to_s)
                record.errors.add(attribute, "unknown value: #{value}")
              end
            end
          end

          class ArrayOfStringsValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_array_of_strings(value)
                record.errors.add(attribute, 'should be an array of strings')
              end
            end
          end

          class BooleanValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_boolean(value)
                record.errors.add(attribute, 'should be a boolean value')
              end
            end
          end

          class DurationValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_duration(value)
                record.errors.add(attribute, 'should be a duration')
              end
            end
          end

          class HashOrStringValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              unless value.is_a?(Hash) || value.is_a?(String)
                record.errors.add(attribute, 'should be a hash or a string')
              end
            end
          end

          class KeyValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              if validate_string(value)
                validate_path(record, attribute, value)
              else
                record.errors.add(attribute, 'should be a string or symbol')
              end
            end

            private

            def validate_path(record, attribute, value)
              path = CGI.unescape(value.to_s)

              if path.include?('/')
                record.errors.add(attribute, 'cannot contain the "/" character')
              elsif path == '.' || path == '..'
                record.errors.add(attribute, 'cannot be "." or ".."')
              end
            end
          end

          class RegexpValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_regexp(value)
                record.errors.add(attribute, 'must be a regular expression')
              end
            end

            private

            def look_like_regexp?(value)
              value.is_a?(String) && value.start_with?('/') &&
                value.end_with?('/')
            end

            def validate_regexp(value)
              look_like_regexp?(value) &&
                Regexp.new(value.to_s[1...-1]) &&
                true
            rescue RegexpError
              false
            end
          end

          class ArrayOfStringsOrRegexpsValidator < RegexpValidator
            def validate_each(record, attribute, value)
              unless validate_array_of_strings_or_regexps(value)
                record.errors.add(attribute, 'should be an array of strings or regexps')
              end
            end

            private

            def validate_array_of_strings_or_regexps(values)
              values.is_a?(Array) && values.all?(&method(:validate_string_or_regexp))
            end

            def validate_string_or_regexp(value)
              return false unless value.is_a?(String)
              return validate_regexp(value) if look_like_regexp?(value)

              true
            end
          end

          class TypeValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              type = options[:with]
              raise unless type.is_a?(Class)

              unless value.is_a?(type)
                message = options[:message] || "should be a #{type.name}"
                record.errors.add(attribute, message)
              end
            end
          end

          class VariablesValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_variables(value)
                record.errors.add(attribute, 'should be a hash of key value pairs')
              end
            end
          end
        end
      end
    end
  end
end
