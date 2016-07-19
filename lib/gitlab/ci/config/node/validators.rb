module Gitlab
  module Ci
    class Config
      module Node
        module Validators
          class AllowedKeysValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              if record.unknown_keys.any?
                unknown_list = record.unknown_keys.join(', ')
                record.errors.add(:config,
                                  "contains unknown keys: #{unknown_list}")
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

          class KeyValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_string(value)
                record.errors.add(attribute, 'should be a string or symbol')
              end
            end
          end

          class TypeValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              type = options[:with]
              raise unless type.is_a?(Class)

              unless value.is_a?(type)
                record.errors.add(attribute, "should be a #{type.name}")
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
