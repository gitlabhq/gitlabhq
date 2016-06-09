module Gitlab
  module Ci
    class Config
      module Node
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
