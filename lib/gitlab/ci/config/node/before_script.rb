module Gitlab
  module Ci
    class Config
      module Node
        class BeforeScript < Entry
          include ValidationHelpers

          def description
            'Script that is executed before the one defined in a job.'
          end

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
