module Gitlab
  module Ci
    class Config
      module Node
        class Null < Entry
          def value
            nil
          end

          def validate!
            nil
          end

          def method_missing(*)
            nil
          end
        end
      end
    end
  end
end
