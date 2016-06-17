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

          class HashValidator < ActiveModel::EachValidator
            def validate_each(record, attribute, value)
              unless value.is_a?(Hash)
                record.errors.add(attribute, 'should be a configuration entry hash')
              end
            end
          end
        end
      end
    end
  end
end
