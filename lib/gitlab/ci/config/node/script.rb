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
          include ValidationHelpers

          def value
            @value.join("\n")
          end

          def validate!
            unless validate_array_of_strings(@value)
              @errors << 'before_script should be an array of strings'
            end
          end
        end
      end
    end
  end
end
