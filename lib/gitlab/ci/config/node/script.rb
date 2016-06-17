module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a script.
        #
        # Each element in the value array is a command that will be executed
        # by GitLab Runner. Currently we concatenate these commands with
        # new line character as a separator, what is compatible with
        # implementation in Runner.
        #
        class Script < Entry
          include Validatable

          validations do
            include LegacyValidationHelpers

            validate :array_of_strings

            def array_of_strings
              unless validate_array_of_strings(self.config)
                errors.add(:config, 'should be an array of strings')
              end
            end
          end

          def value
            @config.join("\n")
          end
        end
      end
    end
  end
end
