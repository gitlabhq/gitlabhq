module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a job script.
        #
        class JobScript < Entry
          include Validatable

          validations do
            include LegacyValidationHelpers

            validate :string_or_array_of_strings

            def string_or_array_of_strings
              unless validate_string(config) || validate_array_of_strings(config)
                errors.add(:config,
                           'should be a string or an array of strings')
              end
            end
          end

          def value
            [@config].flatten
          end
        end
      end
    end
  end
end
