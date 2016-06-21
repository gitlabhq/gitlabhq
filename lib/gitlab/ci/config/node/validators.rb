module Gitlab
  module Ci
    class Config
      module Node
        module Validators
          class ArrayOfStringsValidator < ActiveModel::EachValidator
            include LegacyValidationHelpers

            def validate_each(record, attribute, value)
              unless validate_array_of_strings(value)
                record.errors.add(attribute, 'should be an array of strings')
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
        end
      end
    end
  end
end
