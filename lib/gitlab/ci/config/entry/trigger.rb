module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a trigger policy for the job.
        #
        class Trigger < Node
          include Validatable

          validations do
            include LegacyValidationHelpers

            validate :array_of_strings_or_regexps

            def array_of_strings_or_regexps
              unless validate_array_of_strings_or_regexps(config)
                errors.add(:config, 'should be an array of strings or regexps')
              end
            end
          end
        end
      end
    end
  end
end
