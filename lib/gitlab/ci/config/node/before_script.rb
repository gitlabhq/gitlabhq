module Gitlab
  module Ci
    class Config
      module Node
        class BeforeScript < Entry
          def keys
            {}
          end

          def validate!
          end
        end
      end
    end
  end
end
