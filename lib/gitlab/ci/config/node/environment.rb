module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents environment variables.
        #
        class Environment < Entry
          include Validatable

          validations do
            include LegacyValidationHelpers

            validate do
              unless string_or_array_of_strings?(config)
                errors.add(:config,
                           'should be a string or an array of strings')
              end
            end

            def string_or_array_of_strings?(field)
              validate_string(field) || validate_array_of_strings(field)
            end
          end

          def value
            Array(@config)
          end
        end
      end
    end
  end
end
