module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a job script.
        #
        class Commands < Entry
          include Validatable

          validations do
            include LegacyValidationHelpers

            validate :string_or_array_of_strings

            def string_or_array_of_strings
              unless config_valid?
                errors.add(:config,
                           'should be a string or an array of strings')
              end
            end

            def config_valid?
              validate_string(config) || validate_array_of_strings(config)
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
