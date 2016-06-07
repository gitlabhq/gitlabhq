module Gitlab
  module Ci
    class Config
      module Node
        class Null < Entry
          def method_missing(*)
            nil
          end
        end
      end
    end
  end
end
